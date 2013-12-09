require_relative 'base'

module Chibi
  module Reporter
    module Report
      module Operator
        module Kh
          class Cootel < Base
            def initialize(options = {})
              super(options.merge(:name => "cootel"))
            end
          end
        end
      end
    end
  end
end
