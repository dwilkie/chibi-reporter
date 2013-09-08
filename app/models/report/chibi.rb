require_relative 'base'
require 'httparty'
require 'uri'
require 'active_support/core_ext/integer'
require 'active_support/core_ext/date'
require 'json'

module Report
  class Chibi < Report::Base
    attr_accessor :month, :year

    def initialize(options = {})
      super
      self.month = options[:month] || time_last_month.month
      self.year = options[:year] || time_last_month.year
    end

    def generate!
      generate_remote_report
      self.data = JSON.parse(get_remote_report)
    end

    private

    def generate_remote_report
      HTTParty.post(
        remote_report_url,
        :body => {
          :report => {:month => month, :year => year}
        },
        :basic_auth => remote_url_auth
      )
    end

    def request_remote_report
      HTTParty.get(
        remote_report_url,
        :basic_auth => remote_url_auth
      )
    end

    def get_remote_report
      max_tries = 6
      response = nil
      max_tries.times do
        sleep(10)
        response = request_remote_report.response
        break if response.code == "200"
      end
      response.body
    end

    def data
      @data ||= HTTParty.get
    end

    def remote_url_auth
      basic_auth = {}
      uri = URI.parse(remote_report_url)

      basic_auth[:username] = uri.user
      basic_auth[:password] = uri.password

      basic_auth
    end

    def remote_report_url
      ENV['REMOTE_REPORT_URL']
    end

    def time_last_month
      @time_last_month ||= (Time.now - 1.month)
    end
  end
end
