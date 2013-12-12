require 'spec_helper'
require './lib/chibi/reporter/remote_report'

module Chibi
  module Reporter
    describe RemoteReport do
      include ChibiReporterSpecHelpers::ChibiClient

      describe "#generate!" do
        let(:report_params) { first_request(:body)["report"] }
        let(:env_month) { get_env(:month) }
        let(:env_year) { get_env(:year) }

        def get_env(key)
          ENV["CHIBI_REPORTER_REMOTE_REPORT_#{key.to_s.upcase}"]
        end

        def set_env(key, value)
          normalized_value = value.to_s if value
          ENV["CHIBI_REPORTER_REMOTE_REPORT_#{key.to_s.upcase}"] = normalized_value
        end

        before do
          env_month
          env_year
        end

        after do
          set_env(:month, env_month)
          set_env(:year, env_year)
        end

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

          context "and the environment has CHIBI_REPORTER_REMOTE_REPORT_MONTH=1 CHIBI_REPORTER_REMOTE_REPORT_YEAR=2014" do
            before do
              set_env(:month, 1)
              set_env(:year, 2014)
            end

            it "should request the report to be generated for January 2014" do
              expect_chibi_client_create_remote_report { subject.generate! }
              report_params["year"].should == "2014"
              report_params["month"].should == "1"
            end
          end
        end
      end
    end
  end
end
