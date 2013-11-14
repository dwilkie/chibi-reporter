require_relative 'base'

module Report
  module Operator
    module Kh
      class Smart < Base
        def generate!
          add_worksheet do
            add_logo
            add_title

            add_blank_rows(5)
            add_report_metadata
            add_blank_rows(2)

            add_services_table
          end
          package.serialize("smart.xlsx")
        end
      end
    end
  end
end
