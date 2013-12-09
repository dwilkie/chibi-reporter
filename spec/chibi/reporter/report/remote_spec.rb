require 'spec_helper'
require './lib/chibi/reporter/report/remote'

module Chibi
  module Reporter
    module Report
      describe Remote do
        include WebMockHelpers
        include ChibiReportHelpers

        def asserted_uri
          URI.parse(ENV['CHIBI_REPORTER_REPORT_REMOTE_URL'])
        end

        def expect_remote_request(cassette, options = {}, &block)
          options[:erb] = {:url => asserted_uri.to_s}.merge(options[:erb] || {})
          VCR.use_cassette(cassette, options) do
            yield
          end
        end

        describe ".process!", :focus do
          subject { Remote }

          def asserted_aws_s3_url(bucket, path)
            "https://#{bucket}.s3.amazonaws.com/#{path}"
          end

          def google_drive_upload_urls
            google_drive_urls = []
            asserted_operators.each do |country_code, operators|
              operators.each do |operator_id|
                parent_directory = asserted_google_drive_parent_directory(country_code, operator_id)
                get_year_directory_url = google_drive_find_directory_url(
                  parent_directory, asserted_year_directory
                )
                get_month_directory_url = google_drive_find_directory_url(
                  parent_directory, asserted_month_directory
                )
                post_upload_url = "https://www.googleapis.com/upload/drive/v2/files?alt=json&uploadType=multipart"
                google_drive_urls << {
                  :url => get_year_directory_url, :method => "get", :parent_directory => parent_directory
                }
                google_drive_urls << {
                  :url => get_month_directory_url, :method => "get", :parent_directory => parent_directory
                }
                google_drive_urls << {
                  :url => post_upload_url, :method => "post"
                }
              end
            end
            google_drive_urls
          end

          def google_drive_find_directory_url(parent_directory, title)
            "https://www.googleapis.com/drive/v2/files?q=mimeType='#{asserted_google_docs_folder_mime_type}'%20AND%20trashed=false%20AND%20title='#{title}'%20AND%20'#{parent_directory}'%20in%20parents"
          end

          def asserted_google_drive_parent_directory(country_code, operator_id)
            ENV["CHIBI_REPORTER_REPORT_OPERATOR_#{country_code.to_s.upcase}_#{operator_id.to_s.upcase}_GOOGLE_DRIVE_PARENT_DIRECTORY_ID"]
          end

          def asserted_google_docs_folder_mime_type
            "application/vnd.google-apps.folder"
          end

          def asserted_year_directory
            sample_remote_report["report"]["year"]
          end

          def asserted_month_directory
            Time.new(asserted_year_directory, sample_remote_report["report"]["month"]).strftime("%m_%B").downcase
          end

          def google_drive_oauth_url
            "https://accounts.google.com/o/oauth2/token"
          end

          def expect_get_remote_report(&block)
            expect_remote_request(
              :get_remote_report,
              :erb => {
                :report => sample_remote_report.to_json,
                :aws_s3_metadata_url => asserted_aws_s3_url(
                  ENV['AWS_S3_BUCKET'],
                  ENV['AWS_S3_CHIBI_REPORTER_METADATA_FILE']
                ),
                :google_drive_oauth_url => google_drive_oauth_url,
                :google_drive_upload_urls => google_drive_upload_urls
              },
              &block
            )
          end

          context "given the remote report is not available" do

          end

          context "given the remote report is available" do
            it "should get the remote report" do
              expect_get_remote_report do
                subject.process!
              end
            end
          end
        end

        describe "#generate!" do
          def expect_create_remote_report(&block)
            expect_remote_request(:create_remote_report, &block)
          end

          it "should request a remote report to be generated" do
            expect_create_remote_report do
              subject.generate!
              first_request(:method).should == :post
              uri = first_request.uri
              uri.user.should == asserted_uri.user
              uri.password.should == asserted_uri.password
              uri.path.should == asserted_uri.path
            end
          end

          context "given it's January 2014" do
            before do
              Timecop.freeze(2014, 1, 1)
            end

            after do
              Timecop.return
            end

            context "and no month or year has been specified for this report" do
              it "should request the report to be generated for December 2013" do
                expect_create_remote_report do
                  subject = Remote.new
                  subject.generate!
                  report_params = first_request(:body)["report"]
                  report_params["year"].should == "2013"
                  report_params["month"].should == "12"
                end
              end
            end
          end
        end
      end
    end
  end
end
