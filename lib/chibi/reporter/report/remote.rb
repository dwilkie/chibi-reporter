require 'httparty'
require 'uri'
require 'aws-sdk'
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
                invoice_number += 1
              end
            end
          end
          write_invoice_number(invoice_number) if increment_invoice_number?
        end

        private

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
