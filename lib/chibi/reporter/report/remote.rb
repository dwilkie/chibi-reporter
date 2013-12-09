require 'httparty'
require 'uri'
require 'aws-sdk'
require 'google/api_client'
require 'active_support/core_ext/integer'
require 'active_support/core_ext/date'
require 'json'

Dir[File.join(File.dirname(__FILE__), '**/*.rb')].each { |file| require file }

module Chibi
  module Reporter
    module Report
      class Remote
        attr_accessor :month, :year

        CHIBI_REPORTER_LAST_INVOICE_NUMBER_KEY = "last_invoice_number"

        def initialize(options = {})
          self.month = options[:month] || time_last_month.month
          self.year = options[:year] || time_last_month.year
        end

        def generate!
          # asks for a new remote report to generated
          # this also clears any old reports on the server
          create_remote_report
        end

        def self.process!
          remote_report = get_remote_report
          return unless remote_report
          report_data = remote_report["report"]
          month = report_data["month"]
          year = report_data["year"]
          invoice_number = metadata[CHIBI_REPORTER_LAST_INVOICE_NUMBER_KEY].to_i
          report_data["countries"].each do |country_code, country_data|
            country_data["operators"].each do |operator, operator_data|
              if operator_report = operator_report(
                month, year, invoice_number, country_code, operator, operator_data
              )
                operator_report.generate!
                upload_to_google_drive(operator_report)

                # upload_report_to_s3
                # upload report to google drive
                # email the report to relevant parties if applicable
                #package.serialize("#{name}_#{business_name.gsub(/\s+/, '_').downcase}_invoice_report_#{invoice_period.gsub(/\s+/, '_').downcase}.xlsx")
                invoice_number += 1
              end
            end
          end
          write_invoice_number(invoice_number) if increment_invoice_number?
        end

        private

        def self.upload_to_s3(operator_report)

        end

        def self.upload_to_google_drive(operator_report)
          upload_file_to_drive(
            operator_report.io_stream,
            :title => operator_report.filename,
            :mime_type => operator_report.mime_type,
            :parent_directory => parent_drive_directory(operator_report)
          )
        end

        def self.parent_drive_directory(operator_report)
          find_or_create_drive_directory(
            operator_report.month_directory,
            find_or_create_drive_directory(
              operator_report.year_directory, operator_report.google_drive_parent_directory_id
            )
          )
        end

        def self.find_or_create_drive_directory(title, parent_id)
          (
            JSON.parse(
              google_drive_client.execute(
                :api_method => google_drive.files.list,
                :parameters => {
                  :q => "mimeType='#{drive_directory_mime_type}' AND trashed=false AND title='#{title}' AND '#{parent_id}' in parents"
                }
              ).body
            )["items"].first || {}
          )["id"] || JSON.parse(
            google_drive_client.execute(
              :api_method => google_drive.files.insert,
              :body_object => google_drive.files.insert.request_schema.new(
                "title" => title,
                "mimeType" => drive_directory_mime_type,
                "parents" => ["id" => parent_id]
              )
            ).body
          )["id"]
        end

        def self.drive_directory_mime_type
          'application/vnd.google-apps.folder'
        end

        def self.upload_file_to_drive(file, options = {})
          google_drive_client.execute(
            :api_method => google_drive.files.insert,
            :body_object => google_drive.files.insert.request_schema.new(
              'title' => options[:title],
              'mimeType' => options[:mime_type],
              'parents' => ["id" => options[:parent_directory]]
            ),
            :media => Google::APIClient::UploadIO.new(file, options[:mime_type]),
            :parameters => {
              'uploadType' => 'multipart',
              'alt' => 'json'
            }
          )
        end

        def self.google_drive_client
          return @google_drive_client if @google_drive_client
          @google_drive_client = Google::APIClient.new
          @google_drive_client.authorization.client_id = ENV["GOOGLE_DRIVE_UPLOADER_CLIENT_ID"]
          @google_drive_client.authorization.client_secret = ENV["GOOGLE_DRIVE_UPLOADER_CLIENT_SECRET"]
          @google_drive_client.authorization.scope = ENV["GOOGLE_DRIVE_UPLOADER_OAUTH_SCOPE"]
          @google_drive_client.authorization.refresh_token = ENV["GOOGLE_DRIVE_UPLOADER_REFRESH_TOKEN"]
          @google_drive_client.authorization.grant_type = ENV["GOOGLE_DRIVE_UPLOADER_GRANT_TYPE"]
          @google_drive_client.authorization.fetch_access_token!
          @google_drive_client
        end

        def self.google_drive
          return @google_drive if @google_drive
          google_drive_client.register_discovery_document(
            'drive', 'v2', File.read(ENV["GOOGLE_API_DISCOVERY_DOCUMENT_PATH"])
          )
          @google_drive ||= google_drive_client.discovered_api('drive', 'v2')
        end

        def self.remote_url_auth
          basic_auth = {}
          uri = URI.parse(remote_report_url)

          basic_auth[:username] = uri.user
          basic_auth[:password] = uri.password

          basic_auth
        end

        def self.remote_report_url
          ENV["CHIBI_REPORTER_REPORT_REMOTE_URL"]
        end

        def self.operator_report(month, year, invoice_number, country_code, operator, operator_data)
          operator_report_path = "operator/#{country_code}/#{operator}"
          if File.exists?(File.expand_path("./#{operator_report_path}.rb", File.dirname(__FILE__)))
            "chibi/reporter/report/#{operator_report_path}".classify.constantize.new(
              :data => operator_data,
              :month => month,
              :year => year,
              :invoice_number => invoice_number + 1
            )
          end
        end

        def self.get_remote_report
          response = HTTParty.get(
            remote_report_url,
            :basic_auth => remote_url_auth
          ).response
          JSON.parse(response.body) if response.code == "200"
        end

        def self.s3
          @s3 ||= AWS::S3.new(
            :access_key_id => ENV["AWS_ACCESS_KEY_ID"],
            :secret_access_key => ENV["AWS_SECRET_ACCESS_KEY"]
          )
        end

        def self.bucket
          @bucket ||= s3.buckets[ENV["AWS_S3_BUCKET"]]
        end

        def self.metadata
          @metadata ||= JSON.parse(metadata_file.read)
        end

        def self.metadata_file
          @metadata_file ||= bucket.objects[ENV["AWS_S3_CHIBI_REPORTER_METADATA_FILE"]]
        end

        def self.write_invoice_number(invoice_number)
          metadata_file.write(metadata.merge(CHIBI_REPORTER_LAST_INVOICE_NUMBER_KEY => invoice_number).to_json)
        end

        def self.increment_invoice_number?
          ENV["CHIBI_REPORTER_CONFIG_INCREMENT_INVOICE_NUMBER"].to_i == 1
        end

        private_class_method :operator_report, :get_remote_report,
                             :s3, :bucket, :metadata, :metadata_file,
                             :write_invoice_number, :increment_invoice_number?

        def create_remote_report
          HTTParty.post(
            self.class.remote_report_url,
            :body => {
              :report => {:month => month, :year => year}
            },
            :basic_auth => self.class.remote_url_auth
          )
        end

        def time_last_month
          @time_last_month ||= (Time.current - 1.month)
        end
      end
    end
  end
end
