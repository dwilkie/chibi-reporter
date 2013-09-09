require_relative 'base'

module Report
  module Operator
    module Kh
      class Smart < Report::Operator::Kh::Base
        def generate!
          add_worksheet do
            add_logo
            add_title

            add_blank_rows(5)
            add_report_metadata
            add_blank_rows(2)

            add_table
          end
          package.serialize("smart.xlsx")
        end

        private

        def operator_vat_tin
          "100071112"
        end

        def operator_attention
          "Finance Department"
        end

        def operator_address
          "464A Preah Monivong Blvd,\nSangkat Tonle Bassac,\nKhan Chamkarmorn,\nPhnom Penh"
        end

        def operator_business_name
          "Latelz Co., Ltd"
        end
      end
    end
  end
end
