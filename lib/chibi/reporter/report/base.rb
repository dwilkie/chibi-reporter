module Chibi
  module Reporter
    module Report
      class Base
        CONFIGURATION_PREFIX = "REPORT"
        GLOBAL_CONFIGURATION_PREFIX = "CHIBI_REPORTER"

        private

        def self.configuration(key, *prefixes)
          options = prefixes.extract_options!
          key_prefixes = [CONFIGURATION_PREFIX] + prefixes
          key = key.to_s.upcase

          config = nil

          key_prefixes.size.times do
            full_key = ([GLOBAL_CONFIGURATION_PREFIX] + key_prefixes + [key]).join("_")
            if scope = options[:scope]
              return ENV[full_key] if key_prefixes.last == scope
            else
              config = ENV[full_key]
              return config if config
            end
            key_prefixes.pop
          end
          config
        end

        def configuration(key, *prefixes)
          self.class.configuration(key, *prefixes)
        end

        def aws_s3_root_directory(*parts)
          File.join(configuration(:aws_s3_root_directory, :scope => CONFIGURATION_PREFIX), *parts)
        end

        def mail_recipients(*recipients)
          report_recipients_list(:recipients, *recipients)
        end

        def mail_cc(*recipients)
          report_recipients_list(:cc, *recipients)
        end

        def mail_bcc(*recipients)
          report_recipients_list(:bcc, *recipients)
        end

        def report_recipients_list(list_type, *recipients)
          [*recipients, *(configuration("mail_#{list_type}", :scope => CONFIGURATION_PREFIX) || [])].flatten.join(";").split(";")
        end

        def interpolate(text, interpolations = {})
          interpolated_text = text.dup
          interpolations.each do |key, value|
            interpolated_text.gsub!("%{#{key}}", value)
          end
          interpolated_text
        end
      end
    end
  end
end
