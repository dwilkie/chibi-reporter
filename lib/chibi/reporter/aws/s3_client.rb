module Chibi
  module Reporter
    module Aws
      class S3Client
        require 'aws-sdk'

        def metadata_file
          @metadata_file ||= bucket.objects[ENV["AWS_S3_CHIBI_REPORTER_METADATA_FILE"]]
        end

        private

        def s3
          @s3 ||= ::AWS::S3.new(
            :access_key_id => ENV["AWS_ACCESS_KEY_ID"],
            :secret_access_key => ENV["AWS_SECRET_ACCESS_KEY"]
          )
        end

        def bucket
          @bucket ||= s3.buckets[ENV["AWS_S3_BUCKET"]]
        end
      end
    end
  end
end
