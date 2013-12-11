require 'spec_helper'
require './lib/chibi/reporter/report_generator'

module Chibi
  module Reporter
    describe ReportGenerator do
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
        def expect_report_generator_run!(&block)
          expect_chibi_client_get_remote_report(
            :report_generator_run,
            :erb => {
              :aws_s3_metadata_url => aws_s3_metadata_url,
              :metadata => {:last_invoice_number => last_invoice_number}
            }.merge(
              google_drive_upload_erb(:files => expected_files(:google_drive))
            ).merge(
              aws_s3_upload_erb(:files => expected_files(:aws_s3))
            ),
            &block
          )
        end

        context "given the remote report is available" do
          before do
            expect_report_generator_run! { subject.run! }
          end

          it "should increment the invoice number" do
            num_operator_reports = asserted_operators.inject(0) {|total, (k, v)| total + v.size}
            subject.invoice_number.should == num_operator_reports + last_invoice_number
          end

          it "should send an email for each operator report" do
            with_asserted_operators do |country_code, operator_id, index|
              mail_delivery = mail_deliveries[index]
              mail_delivery.from.should == [mail_sender(country_code, operator_id)]
              mail_delivery.to.should == mail_recipients(country_code, operator_id)
              mail_delivery.cc.should == mail_cc(country_code, operator_id)
              mail_delivery.bcc.should == mail_bcc(country_code, operator_id)
              mail_delivery.subject.should == mail_subject(
                report_year, report_month, country_code, operator_id
              )
              mail_delivery.text_part.decoded.should == mail_body(
                report_year, report_month, country_code, operator_id
              )
              attachment = mail_delivery.attachments.first
              attachment.filename.should == File.basename(
                operator_suggested_filename(
                  report_year, report_month, country_code, operator_id
                )
              )
              attachment.content_type.split(";").first.should == mime_type
            end
          end
        end
      end
    end
  end
end
