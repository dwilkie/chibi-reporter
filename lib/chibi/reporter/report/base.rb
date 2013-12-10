module Chibi
  module Reporter
    module Report
      class Base
        private

        def aws_s3_root_directory(*parts)
          File.join(ENV["CHIBI_REPORTER_REPORT_AWS_S3_ROOT_DIRECTORY"], *parts)
        end
      end
    end
  end
end
