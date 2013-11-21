require_relative 'base'

module Chibi
  module Reporter
    module Report
      module Operator
        module Kh
          class Smart < Base
            def generate!
              add_invoice
              package.serialize("smart.xlsx")
            end

            private

            def add_invoice_sections
              super
              add_verification
            end

            def add_verification
              add_section_header(:verification)
              add_row_tabulated_data(verification_rows)
            end

            def verification_rows
              @verification_rows ||= [
                {:columns => [row_tabulated_datum(:issued_by), row_tabulated_datum(:checked_by), row_tabulated_datum(:approved_by)]},
                {:columns => [row_tabulated_datum(:name), row_tabulated_datum(:name), row_tabulated_datum(:name)]},
                {:columns => [row_tabulated_datum(:date), row_tabulated_datum(:date), row_tabulated_datum(:date)]}
              ]
            end
          end
        end
      end
    end
  end
end
