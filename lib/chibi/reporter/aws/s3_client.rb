module Chibi
  module Reporter
    module Aws
      class S3Client
        require 'aws-sdk'

        def metadata
          @metadata ||= metadata_object.get.body.read
        end

        def write_metadata(data)
          metadata_object.put(:body => data)
        end

        def upload(file, options = {})
          key = File.join(object_key(options[:root_directory]), options[:filename])
          object(key).put(:body => file)
        end

        private

        def metadata_object
          @metadata_object ||= object(metadata_file_key)
        end

        def metadata_file_key
          object_key(ENV["CHIBI_REPORTER_AWS_S3_METADATA_FILE"])
        end

        def object_key(key)
          File.join(ENV["CHIBI_REPORTER_AWS_S3_ROOT_DIRECTORY"], key)
        end

        def s3
          @s3 ||= ::Aws::S3::Resource.new
        end

        def bucket
          @bucket ||= s3.bucket(bucket_name)
        end

        def object(key)
          bucket.object(key)
        end

        def bucket_name
          ENV["AWS_S3_BUCKET"]
        end
      end
    end
  end
end
