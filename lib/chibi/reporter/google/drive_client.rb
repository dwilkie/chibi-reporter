module Chibi
  module Reporter
    module Google
      class DriveClient
        require 'googleauth'
        require 'google/apis/drive_v2'
        require 'json'

        def upload(file, options = {})
          upload_file(
            options[:title] || File.basename(options[:filename]),
            find_or_create_directory_structure(options[:filename], options[:root_directory]),
            options[:mime_type],
            file
          )
        end

        private

        def find_or_create_directory_structure(filename, root_directory)
          parent_directories = File.dirname(filename).split("/")
          parent_directories.each do |parent_directory|
            root_directory = find_or_create_directory(parent_directory, root_directory)
          end
          root_directory
        end

        def find_or_create_directory(title, parent_id)
          get_directory(title, parent_id) || create_directory(title, parent_id)
        end

        def directory_mime_type
          'application/vnd.google-apps.folder'
        end

        def get_directory(title, parent_id)
          directory = drive.list_files(:q => "mimeType='#{directory_mime_type}' AND trashed=false AND title='#{title}' AND '#{parent_id}' in parents").items.first
          directory && directory.id
        end

        def create_directory(title, parent_id)
          upload_file(title, parent_id, directory_mime_type).id
        end

        def upload_file(title, parent_directory_id, mime_type, file = nil)
          drive.insert_file(
            {
              :title => title,
              :mime_type => mime_type,
              :parents => [{:id => parent_directory_id}]},
            :upload_source => file
          )
        end

        def drive
          return @drive if @drive
          ::Google::Apis::RequestOptions.default.retries = 5
          @drive = ::Google::Apis::DriveV2::DriveService.new
          @drive.authorization = ::Google::Auth.get_application_default([::Google::Apis::DriveV2::AUTH_DRIVE])
          @drive.authorization.grant_type = ENV["GOOGLE_GRANT_TYPE"]
          @drive
        end
      end
    end
  end
end
