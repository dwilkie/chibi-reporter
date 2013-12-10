require 'spec_helper'
require './lib/chibi/reporter/google/drive_client'

module Chibi
  module Reporter
    module Google
      describe DriveClient do
        include ChibiReporterSpecHelpers::Google::DriveClient

        describe "#upload(file, options = {})" do
          let(:file_contents) { "bar" }
          let(:file) { StringIO.new(file_contents) }
          let(:filename) { "directory/filename.txt" }
          let(:root_directory) { "root" }
          let(:mime_type) { "text/plain" }

          it "should upload the file to Google Drive" do
            expect_external_request(
              :google_drive_client_upload, :erb => google_drive_upload_erb(
                :files => [{:filename => filename, :root_directory => root_directory}]
              )
            ) do
              subject.upload(
                file,
                :filename => filename,
                :mime_type => mime_type,
                :root_directory => root_directory
              )
            end

            uploaded_file = last_request(:body)["filename"]
            uploaded_file.should include(mime_type)
            uploaded_file.should include(file_contents)
          end
        end
      end
    end
  end
end
