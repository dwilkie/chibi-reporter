require 'spec_helper'
require './lib/chibi/reporter/report/operator/kh/smart'

module Chibi
  module Reporter
    module Report
      module Operator
        module Kh
          describe Smart do
            include ChibiReporterSpecHelpers::Report::Operator::Kh

            let(:operator_id) { :smart }
            let(:operator_class) { Smart }

            it_should_behave_like "an operator report"
          end
        end
      end
    end
  end
end
