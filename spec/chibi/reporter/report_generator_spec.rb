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

      def expected_files
        files = []
        asserted_operators.each do |country_code, operator_ids|
          operator_ids.each do |operator_id|
            files << {
              :filename => File.join(report_year.to_s, month_directory, "foo.xlsx"),
              :root_directory => ENV["CHIBI_REPORTER_REPORT_OPERATOR_#{country_code.to_s.upcase}_#{operator_id.to_s.upcase}_GOOGLE_DRIVE_ROOT_DIRECTORY_ID"]
            }
          end
        end
        files
      end

      describe "#run!" do
        def expect_report_generator_run!(&block)
          expect_chibi_client_get_remote_report(
            :report_generator_run,
            :erb => {:aws_s3_metadata_url => aws_s3_metadata_url}.merge(
              google_drive_upload_erb(:files => expected_files)
            ),
            &block
          )
        end

        context "given the remote report is available" do
          it "should generate and distribute operator reports" do
            expect_report_generator_run! { subject.run! }
          end
        end
      end
    end
  end
end
