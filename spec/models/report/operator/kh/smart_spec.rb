require 'spec_helper'
require './app/models/report/operator/kh/smart'

module Report
  module Operator
    module Kh
      describe Smart, :focus do
        include ChibiReportHelpers

        def sample_operator_report
          super(:kh, :smart)
        end

        subject { Smart.new(:data => sample_operator_report) }

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
