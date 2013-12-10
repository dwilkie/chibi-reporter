require_relative 'base'

module Chibi
  module Reporter
    module Report
      module Operator
        module Kh
          class Qb < Base
            def self.enabled?
              super(ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_QB_ENABLED"])
            end

            def google_drive_root_directory_id
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_QB_GOOGLE_DRIVE_ROOT_DIRECTORY_ID"]
            end

            def human_name
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_QB_HUMAN_NAME"]
            end

            private

            def billing_name
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_QB_BILLING_NAME"]
            end

            def billing_address
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_QB_BILLING_ADDRESS"]
            end

            def billing_vat_tin
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_QB_BILLING_VAT_TIN"]
            end

            def billing_attention
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_QB_BILLING_ATTENTION"]
            end
          end
        end
      end
    end
  end
end
