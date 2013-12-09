require 'spec_helper'
require './lib/chibi/reporter/report/operator/kh/cootel'

module Chibi
  module Reporter
    module Report
      module Operator
        module Kh
          describe Cootel do
            include ChibiReportHelpers::Kh

            let(:operator_id) { :cootel }
            let(:operator_class) { Cootel }

            it_should_behave_like "an operator report"
          end
        end
      end
    end
  end
end
