require 'spec_helper'
require './app/models/report/remote'

module Report
  describe Remote do
    include WebMockHelpers

    def asserted_uri
      URI.parse(ENV['REMOTE_REPORT_URL'])
    end

    describe ".process!", :focus do
      def expect_get_remote_report(&block)
        VCR.use_cassette(:get_remote_report) do
          yield
        end
      end

      def report
        Remote
      end

      context "given the remote report is not available" do

      end

      context "given the remote report is available" do
        it "should get the remote report" do

          expect_get_remote_report do
            report.process!
          end
        end
      end
    end

    describe "#generate!" do
      def expect_create_remote_report(&block)
        VCR.use_cassette(:create_remote_report) do
          yield
        end
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
