require 'spec_helper'
require './app/models/report/chibi'

module Report
  describe Chibi do
    describe "#generate!" do
      include WebMockHelpers

      def asserted_uri
        URI.parse(ENV['REMOTE_REPORT_URL'])
      end

      def expect_remote_report_request(&block)
        VCR.use_cassette(:remote_report) do
          yield
        end
      end

      before do
        subject.stub(:sleep)
      end

      it "should request a remote report to be generated", :focus do
        expect_remote_report_request do
          subject.generate!
          first_request(:method).should == :post
          uri = first_request.uri
          uri.user.should == asserted_uri.user
          uri.password.should == asserted_uri.password
          uri.path.should == asserted_uri.path
        end
      end

      it "should sleep for 10 seconds" do
        expect_remote_report_request do
          subject.should_receive(:sleep).with(10)
          subject.generate!
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
            expect_remote_report_request do
              subject = Chibi.new
              subject.stub(:sleep)
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
