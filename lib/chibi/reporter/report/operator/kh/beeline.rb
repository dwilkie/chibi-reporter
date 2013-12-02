require_relative 'base'

module Chibi
  module Reporter
    module Report
      module Operator
        module Kh
          class Beeline < Base
            def generate!
              add_invoice
              package.serialize("beeline.xlsx")
            end

            private

            def billing_name
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_BEELINE_BILLING_NAME"]
            end

            def billing_address
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_BEELINE_BILLING_ADDRESS"]
            end

            def billing_vat_tin
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_BEELINE_BILLING_VAT_TIN"]
            end

            def billing_attention
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_BEELINE_BILLING_ATTENTION"]
            end

            def bank_name
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_BEELINE_BUSINESS_BANK_NAME"]
            end

            def bank_account_number
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_BEELINE_BUSINESS_BANK_ACCOUNT_NUMBER"]
            end

            def bank_swift_code
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_BEELINE_BUSINESS_BANK_SWIFT_CODE"]
            end

            def bank_address
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_BEELINE_BUSINESS_BANK_ADDRESS"]
            end
          end
        end
      end
    end
  end
end
