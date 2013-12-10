module Chibi
  module Reporter
    module Aws
      class S3Client
        require 'aws-sdk'

        def metadata_file
          @metadata_file ||= bucket.objects[metadata_file_key]
        end

        def upload(file, options = {})
          key = File.join(object_key(options[:root_directory]), options[:filename])
          bucket.objects[key].write(file)
        end

        private

        def metadata_file_key
          object_key(ENV["CHIBI_REPORTER_AWS_S3_METADATA_FILE"])
        end

        def object_key(key)
          File.join(ENV["CHIBI_REPORTER_AWS_S3_ROOT_DIRECTORY"], key)
        end

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
