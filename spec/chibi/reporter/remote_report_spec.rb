require 'spec_helper'
require './lib/chibi/reporter/remote_report'

module Chibi
  module Reporter
    describe RemoteReport do
      include ChibiReporterSpecHelpers::ChibiClient

      describe "#generate!(month = nil, year = nil)" do
        let(:report_params) { first_request(:body)["report"] }

        context "given it's January 2014" do
          context "and no args are passed" do
            it "should request the report to be generated for December 2013" do
              Timecop.freeze(Time.local(2014, 1, 1)) do
                expect_chibi_client_create_remote_report { subject.generate! }
              end

              report_params["year"].should == "2013"
              report_params["month"].should == "12"
            end
          end

          context "passing 1, 2014" do
            it "should request the report to be generated for January 2014" do
              expect_chibi_client_create_remote_report { subject.generate!(1, 2014) }
              report_params["year"].should == "2014"
              report_params["month"].should == "1"
            end
          end
        end
      end
    end
  end
end
