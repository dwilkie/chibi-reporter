module Chibi
  module Reporter
    class ChibiClient
      require 'httparty'
      require 'uri'
      require 'json'

      def get_remote_report
        response = HTTParty.get(
          remote_report_url,
          :basic_auth => remote_url_auth
        ).response
        JSON.parse(response.body) if response.code == "200"
      end

      def create_remote_report(month, year)
        HTTParty.post(
          remote_report_url,
          :body => {
            :report => {:month => month, :year => year}
          },
          :basic_auth => remote_url_auth
        )
      end

      private

      def remote_report_url
        ENV["CHIBI_REPORTER_CLIENT_REMOTE_REPORT_URL"]
      end

      def remote_url_auth
        basic_auth = {}
        uri = URI.parse(remote_report_url)

        basic_auth[:username] = uri.user
        basic_auth[:password] = uri.password

        basic_auth
      end
    end
  end
end
