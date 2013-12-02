require 'spec_helper'
require './lib/chibi/reporter/report/operator/kh/beeline'

module Chibi
  module Reporter
    module Report
      module Operator
        module Kh
          describe Beeline, :focus do
            include ChibiReportHelpers

            def sample_operator_report
              super(:kh, :beeline)
            end

            subject {
              Beeline.new(:data => sample_operator_report, :month => 1, :year => 2014, :invoice_number => 1)
            }

            describe "#generate!" do
              it "should create an invoice for Beeline" do
                subject.generate!
                File.should exist("beeline.xlsx")
              end
            end
          end
        end
      end
    end
  end
end
