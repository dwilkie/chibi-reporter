require_relative 'base'

module Chibi
  module Reporter
    module Report
      module Operator
        module Kh
          class Smart < Base
            CONFIGURATION_PREFIX = "SMART"

            def aws_s3_root_directory
              super(configuration(:aws_s3_root_directory, :scope => CONFIGURATION_PREFIX))
            end

            def mail_recipients
              super(*recipients_list(:recipients))
            end

            def mail_cc
              super(*recipients_list(:cc))
            end

            def mail_bcc
              super(*recipients_list(:bcc))
            end

            private

            def recipients_list(list_type)
              [*(configuration("mail_#{list_type}", :scope => CONFIGURATION_PREFIX) || [])]
            end

            def self.configuration(key, *args)
              super(key, CONFIGURATION_PREFIX, *args)
            end
          end
        end
      end
    end
  end
end
