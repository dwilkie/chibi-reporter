require 'httparty'
require 'uri'
require 'active_support/core_ext/integer'
require 'active_support/core_ext/date'
require 'json'

Dir[File.join(File.dirname(__FILE__), '**/*.rb')].each { |file| require file }

module Chibi
  module Reporter
    module Report
      class Remote
        attr_accessor :month, :year

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
          report_data["countries"].each do |country_code, country_data|
            country_data["operators"].each do |operator, operator_data|
              if operator_report = operator_report(country_code, operator, operator_data)
                operator_report.generate!
              end
            end
          end
        end

        private

        def self.operator_report(country_code, operator, operator_data)
          operator_report_path = "operator/#{country_code}/#{operator}"
          if File.exists?(File.expand_path("./#{operator_report_path}.rb", File.dirname(__FILE__)))
            "chibi/reporter/report/#{operator_report_path}".classify.constantize.new(:data => operator_data)
          end
        end
        private_class_method :operator_report

        def self.get_remote_report
          response = HTTParty.get(
            remote_report_url,
            :basic_auth => remote_url_auth
          ).response
          JSON.parse(response.body) if response.code == "200"
        end
        private_class_method :get_remote_report

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
