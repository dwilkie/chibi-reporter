require 'spec_helper'
require './lib/chibi/reporter/chibi_client'

module Chibi
  module Reporter
    describe ChibiClient do
      include ChibiReporterSpecHelpers::ChibiClient

      describe "#get_remote_report" do
        context "given the remote report is not available" do
          it "should return nil" do
            expect_chibi_client_get_remote_report(:chibi_client_get_remote_report_404) do
              expect(subject.get_remote_report).to be_nil
            end
          end
        end

        context "given the remote report is available" do
          it "should return the report as a hash" do
            expect_chibi_client_get_remote_report do
              expect(subject.get_remote_report).to be_a(Hash)
            end
            assert_chibi_client_remote_report_request(:get)
          end
        end
      end

      describe "#create_remote_report(month, year)" do
        it "should request a remote report to be generated for the given month and year" do
          expect_chibi_client_create_remote_report do
            subject.create_remote_report(1, 2014)
          end
          assert_chibi_client_remote_report_request(:post)
        end
      end
    end
  end
end
