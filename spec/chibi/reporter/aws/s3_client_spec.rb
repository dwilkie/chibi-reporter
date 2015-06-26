require 'spec_helper'
require './lib/chibi/reporter/aws/s3_client'

module Chibi
  module Reporter
    module Aws
      describe S3Client do
        include ChibiReporterSpecHelpers::Aws::S3Client

        describe "#metadata" do
          it "should return the correct metadata file" do
            expect_external_request(:aws_s3_metadata_download, :erb => {:aws_s3_metadata_url => aws_s3_metadata_url}) do
              expect(JSON.parse(subject.metadata)).to be_a(Hash)
            end
          end
        end

        describe "#upload(file, options)" do
          let(:file_contents) { "bar" }
          let(:file) { StringIO.new(file_contents) }
          let(:filename) { "foo.txt" }
          let(:root_directory) { "some/directory" }

          it "should upload the file to the configured s3 bucket" do
            expect_external_request(
              "aws_s3_upload",
              :erb => aws_s3_upload_erb(
                :files => [:filename => filename, :root_directory => root_directory]
              )
            ) { subject.upload(file, :filename => filename, :root_directory => root_directory) }

            expect(last_request.body).to eq(file_contents)
          end
        end
      end
    end
  end
end
