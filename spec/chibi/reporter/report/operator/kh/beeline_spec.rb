require 'spec_helper'
require './lib/chibi/reporter/report/operator/kh/beeline'

module Chibi
  module Reporter
    module Report
      module Operator
        module Kh
          describe Beeline do
            include ChibiReporterSpecHelpers::Report::Operator::Kh

            let(:operator_id) { :beeline }
            let(:operator_class) { Beeline }

            it_should_behave_like "an operator report"
          end
        end
      end
    end
  end
end
