require 'spec_helper'
require './lib/chibi/reporter/report/operator/kh/qb'

module Chibi
  module Reporter
    module Report
      module Operator
        module Kh
          describe Qb do
            include ChibiReportHelpers::Kh

            let(:operator_id) { :qb }
            let(:operator_class) { Qb }

            it_should_behave_like "an operator report"
          end
        end
      end
    end
  end
end
