require 'spec_helper'
require './lib/chibi/reporter/report_generator'

describe Chibi::Reporter::ReportGenerator do
  include ChibiReporterSpecHelpers::ChibiClient
  include ChibiReporterSpecHelpers::Aws::S3Client
  include ChibiReporterSpecHelpers::Google::DriveClient
  include ChibiReporterSpecHelpers::MailAssertions

  def report_year
    sample_remote_report["report"]["year"]
  end

  def report_month
    sample_remote_report["report"]["month"]
  end

  def expected_files(upload_type)
    files = []
    with_asserted_operators do |country_code, operator_id|
      files << {
        :filename => operator_suggested_filename(report_year, report_month, country_code, operator_id),
        :root_directory => send("#{upload_type}_root_directory", country_code, operator_id)
      }
    end
    files
  end

  describe "#run!" do
    let(:last_invoice_number) { 40 }
    def expect_report_generator_run!(options = {}, &block)
      metadata = {
        "reports" => {
          "operator" => {
            "last_invoice_number" => last_invoice_number
          }.merge(options[:reports_operator_metadata] || {})
        }
      }.deep_merge(options[:metadata] || {})
      expect_chibi_client_get_remote_report(
        :report_generator_run,
        :erb => {
          :aws_s3_metadata_url => aws_s3_metadata_url,
          :metadata => metadata#.to_json
        }.merge(
          google_drive_upload_erb(:files => expected_files(:google_drive))
        ).merge(
          aws_s3_upload_erb(:files => expected_files(:aws_s3))
        ),
        &block
      )
    end

    context "given the remote report is not available" do
      it "should raise an error" do
        expect {
          expect_chibi_client_get_remote_report(:chibi_client_get_remote_report_404) { subject.run! }
        }.to raise_error(RuntimeError, "remote report not yet available")

        expect(last_request(:url)).to eq(get_url_without_auth(chibi_client_remote_report_uri.to_s))
        expect(mail_deliveries).to be_empty
      end
    end

    context "given the remote report is available" do
      def expect_report_generator_run!(options = {})
        super(options) { subject.run! }
      end

      context "but operator reports have already been generated for this month and year" do
        def expect_report_generator_run!
          super(:reports_operator_metadata => {report_year => {report_month => 2.days.ago}})
        end

        it "should not generate any reports" do
          expect_report_generator_run!
          expect(last_request(:url)).to eq(aws_s3_metadata_url)
          expect(last_request(:method)).to eq(:get)
          expect(mail_deliveries).to be_empty
        end

        context "and the environment has CHIBI_REPORTER_REPORT_FORCE_GENERATE=1" do
          let(:force_generate) { get_env }

          def set_env(value)
            normalized_value = value.to_s
            ENV["CHIBI_REPORTER_REPORT_FORCE_GENERATE"] = normalized_value if value
          end

          def get_env
            ENV["CHIBI_REPORTER_REPORT_FORCE_GENERATE"]
          end

          before do
            force_generate
          end

          after do
            set_env(force_generate)
          end

          it "should generate the reports but not email them" do
            set_env(1)
            expect_report_generator_run!
            expect(last_request(:url)).to eq(google_drive_upload_file_url(:upload_id => true))
            expect(last_request(:method)).to eq(google_drive_upload_file_method)
            expect(mail_deliveries).to be_empty
          end
        end
      end

      context "and no operator reports have been generated for this month and year" do
        it "should increment the metadata for the last invoice number" do
          Timecop.freeze(Time.current) do
            expect_report_generator_run!
            num_operator_reports = asserted_operators.inject(0) {|total, (k, v)| total + v.size}
            asserted_last_invoice_number = num_operator_reports + last_invoice_number
            expect(last_request(:url)).to eq(aws_s3_metadata_url)
            metadata_update = JSON.parse(last_request.body)["reports"]["operator"]
            expect(metadata_update["last_invoice_number"]).to eq(asserted_last_invoice_number)
            expect(metadata_update[report_year.to_s][report_month.to_s]).to eq(Time.current.to_s)
          end
        end

        it "should send an email for each operator report" do
          expect_report_generator_run!
          with_asserted_operators(:email_enabled => true) do |country_code, operator_id, index|
            mail_delivery = mail_deliveries[index]
            expect(mail_delivery.from).to eq([mail_sender(country_code, operator_id)])
            expect(mail_delivery.to).to eq(mail_recipients(country_code, operator_id))
            expect(mail_delivery.cc).to eq(mail_cc(country_code, operator_id))
            expect(mail_delivery.bcc).to eq(mail_bcc(country_code, operator_id))
            expect(mail_delivery.subject).to eq(mail_subject(
              report_year, report_month, country_code, operator_id
            ))
            expect(mail_delivery.text_part.decoded).to eq(mail_body(
              report_year, report_month, country_code, operator_id
            ))
            attachment = mail_delivery.attachments.first
            expect(attachment.body.decoded.size).to be > 0
            expect(attachment.filename).to eq(File.basename(
              operator_suggested_filename(
                report_year, report_month, country_code, operator_id
              )
            ))
            expect(attachment.content_type.split(";").first).to eq(mime_type)
          end
        end
      end
    end
  end
end
