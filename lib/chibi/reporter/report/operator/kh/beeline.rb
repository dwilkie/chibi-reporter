require_relative 'base'

module Chibi
  module Reporter
    module Report
      module Operator
        module Kh
          class Beeline < Base
            def self.enabled?
              super(ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_BEELINE_ENABLED"])
            end

            def google_drive_root_directory_id
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_BEELINE_GOOGLE_DRIVE_ROOT_DIRECTORY_ID"]
            end

            def aws_s3_root_directory
              super(ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_BEELINE_AWS_S3_ROOT_DIRECTORY"])
            end

            private

            def human_name
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_BEELINE_HUMAN_NAME"]
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
          end
        end
      end
    end
  end
end
