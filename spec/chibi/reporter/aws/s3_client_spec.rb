require 'spec_helper'
require './lib/chibi/reporter/aws/s3_client'

module Chibi
  module Reporter
    module Aws
      describe S3Client do
        include ChibiReporterSpecHelpers::Aws::S3Client

        describe "#metadata_file" do
          it "should return the correct metadata file" do
            subject.metadata_file.public_url.to_s.should == aws_s3_metadata_url
          end
        end
      end
    end
  end
end
