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

            def billing_name
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_SMART_BILLING_NAME"]
            end

            def billing_address
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_SMART_BILLING_ADDRESS"]
            end

            def billing_vat_tin
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_SMART_BILLING_VAT_TIN"]
            end

            def billing_attention
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_SMART_BILLING_ATTENTION"]
            end
          end
        end
      end
    end
  end
end
