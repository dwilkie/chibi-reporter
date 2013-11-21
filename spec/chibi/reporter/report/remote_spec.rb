require 'spec_helper'
require './lib/chibi/reporter/report/remote'

module Chibi
  module Reporter
    module Report
      describe Remote do
        include WebMockHelpers
        include ChibiReportHelpers

        def asserted_uri
          URI.parse(ENV['REMOTE_REPORT_URL'])
        end

        def expect_remote_request(cassette, options = {}, &block)
          options[:erb] = {:url => asserted_uri.to_s}.merge(options[:erb] || {})
          VCR.use_cassette(cassette, options) do
            yield
          end
        end

        describe ".process!", :focus do
          subject { Remote }

          def expect_get_remote_report(&block)
            expect_remote_request(
              :get_remote_report,
              :erb => {:report => sample_remote_report.to_json},
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
