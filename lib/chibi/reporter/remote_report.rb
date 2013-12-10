module Chibi
  module Reporter
    class RemoteReport
      require_relative './chibi_client'

      require 'active_support/core_ext/integer'
      require 'active_support/core_ext/date'

      attr_accessor :month, :year

      def initialize(options = {})
        self.month = options[:month] || time_last_month.month
        self.year = options[:year] || time_last_month.year
      end

      def generate!
        # asks for a new remote report to generated
        # this also clears any old reports on the server
        chibi_client.create_remote_report(month, year)
      end

      private

      def chibi_client
        @chibi_client ||= ChibiClient.new
      end

      def time_last_month
        @time_last_month ||= (Time.current - 1.month)
      end
    end
  end
end
