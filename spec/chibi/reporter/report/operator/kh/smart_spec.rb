require 'spec_helper'
require './lib/chibi/reporter/report/operator/kh/smart'

module Chibi
  module Reporter
    module Report
      module Operator
        module Kh
          describe Smart, :focus do
            include ChibiReportHelpers

            def sample_operator_report
              super(:kh, :smart)
            end

            subject { Smart.new(:data => sample_operator_report, :month => 1, :year => 2014) }

            describe "#generate!" do
              it "should do something" do
                subject.generate!
                File.should exist("smart.xlsx")
              end
            end
          end
        end
      end
    end
  end
end
