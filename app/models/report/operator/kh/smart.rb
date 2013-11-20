require_relative 'base'

module Report
  module Operator
    module Kh
      class Smart < Base
        def generate!
          add_worksheet do
            add_logo
            add_title
            add_business_details
            add_services
            add_payment_instructions
          end
          package.serialize("smart.xlsx")
        end
      end
    end
  end
end
