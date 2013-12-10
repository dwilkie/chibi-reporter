require 'spec_helper'
require './lib/chibi/reporter/remote_report'

module Chibi
  module Reporter
    describe RemoteReport do
      include ChibiReporterSpecHelpers::ChibiClient

      describe "#generate!" do
        context "given it's January 2014" do
          context "and no month or year has been specified for this report" do
            it "should request the report to be generated for December 2013" do
              Timecop.freeze(2014, 1, 1) do
                expect_chibi_client_create_remote_report { subject.generate! }
              end

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
