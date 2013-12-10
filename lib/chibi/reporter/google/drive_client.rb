module Chibi
  module Reporter
    module Google
      class DriveClient
        require 'google/api_client'
        require 'json'

        def upload(file, options = {})
          upload_file(
            file,
            :title => options[:title] || File.basename(options[:filename]),
            :mime_type => options[:mime_type],
            :parent_directory => find_or_create_directory_structure(
              options[:filename], options[:root_directory]
            )
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
          (
            JSON.parse(
              client.execute(
                :api_method => api.files.list,
                :parameters => {
                  :q => "mimeType='#{directory_mime_type}' AND trashed=false AND title='#{title}' AND '#{parent_id}' in parents"
                }
              ).body
            )["items"].first || {}
          )["id"] || JSON.parse(
            client.execute(
              :api_method => api.files.insert,
              :body_object => api.files.insert.request_schema.new(
                "title" => title,
                "mimeType" => directory_mime_type,
                "parents" => ["id" => parent_id]
              )
            ).body
          )["id"]
        end

        def directory_mime_type
          'application/vnd.google-apps.folder'
        end

        def upload_file(file, options = {})
          client.execute(
            :api_method => api.files.insert,
            :body_object => api.files.insert.request_schema.new(
              'title' => options[:title],
              'mimeType' => options[:mime_type],
              'parents' => ["id" => options[:parent_directory]]
            ),
            :media => ::Google::APIClient::UploadIO.new(file, options[:mime_type]),
            :parameters => {
              'uploadType' => 'multipart',
              'alt' => 'json'
            }
          )
        end

        def client
          return @client if @client
          @client = ::Google::APIClient.new(
            :application_name => "chibi-reporter",
            :application_version => "0.0.1"
          )
          @client.authorization.client_id = ENV["GOOGLE_DRIVE_UPLOADER_CLIENT_ID"]
          @client.authorization.client_secret = ENV["GOOGLE_DRIVE_UPLOADER_CLIENT_SECRET"]
          @client.authorization.scope = ENV["GOOGLE_DRIVE_UPLOADER_OAUTH_SCOPE"]
          @client.authorization.refresh_token = ENV["GOOGLE_DRIVE_UPLOADER_REFRESH_TOKEN"]
          @client.authorization.grant_type = ENV["GOOGLE_DRIVE_UPLOADER_GRANT_TYPE"]
          @client.authorization.fetch_access_token!
          @client
        end

        def api
          return @api if @api
          client.register_discovery_document(
            'drive', 'v2', File.read(ENV["GOOGLE_API_DISCOVERY_DOCUMENT_PATH"])
          )
          @api = client.discovered_api('drive', 'v2')
        end
      end
    end
  end
end
