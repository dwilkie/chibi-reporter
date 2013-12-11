require_relative "../base"

module Chibi
  module Reporter
    module Report
      module Operator
        class Base < Report::Base
          CONFIGURATION_PREFIX = "OPERATOR"

          private

          def aws_s3_root_directory(*parts)
            super(configuration(:aws_s3_root_directory, :scope => CONFIGURATION_PREFIX), *parts)
          end

          def mail_recipients(*recipients)
            super(*recipients, *operator_recipients_list(:recipients))
          end

          def mail_cc(*recipients)
            super(*recipients, *operator_recipients_list(:cc))
          end

          def mail_bcc(*recipients)
            super(*recipients, *operator_recipients_list(:bcc))
          end

          def operator_recipients_list(list_type)
            [*(configuration("mail_#{list_type}", :scope => CONFIGURATION_PREFIX) || [])]
          end

          def self.configuration(key, *prefixes)
            super(key, CONFIGURATION_PREFIX, *prefixes)
          end
        end
      end
    end
  end
end
