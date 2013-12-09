require_relative 'base'

module Chibi
  module Reporter
    module Report
      module Operator
        module Kh
          class Qb < Base
            def initialize(options = {})
              super(options.merge(:name => "qb"))
            end
          end
        end
      end
    end
  end
end
