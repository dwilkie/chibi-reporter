require_relative "../base"

module Chibi
  module Reporter
    module Report
      module Operator
        class Base < Report::Base
          private

          def aws_s3_root_directory(*parts)
            super(ENV["CHIBI_REPORTER_REPORT_OPERATOR_AWS_S3_ROOT_DIRECTORY"], *parts)
          end
        end
      end
    end
  end
end
