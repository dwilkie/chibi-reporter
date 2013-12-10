require 'spec_helper'
require './lib/chibi/reporter/report_generator'

module Chibi
  module Reporter
    describe ReportGenerator do
      include ChibiReporterSpecHelpers::ChibiClient
      include ChibiReporterSpecHelpers::Aws::S3Client
      include ChibiReporterSpecHelpers::Google::DriveClient

      def report_year
        sample_remote_report["report"]["year"]
      end

      def report_month
        sample_remote_report["report"]["month"]
      end

      def month_directory
        Time.new(report_year, report_month).strftime("%m_%B").downcase
      end

      def expected_files(upload_type)
        files = []
        asserted_operators.each do |country_code, operator_ids|
          operator_ids.each do |operator_id|
            files << {
              :filename => operator_suggested_filename(report_year.to_s, month_directory, country_code, operator_id),
              :root_directory => send("#{upload_type}_root_directory", country_code, operator_id)
            }
          end
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
          it "should generate and distribute operator reports" do
            expect_report_generator_run! { subject.run! }
            num_operator_reports = asserted_operators.inject(0) {|total, (k, v)| total + v.size}
            subject.invoice_number.should == num_operator_reports + last_invoice_number
          end
        end
      end
    end
  end
end
