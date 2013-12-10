module Chibi
  module Reporter
    class RemoteReport
      require_relative './chibi_client'

      require 'active_support/core_ext/integer'
      require 'active_support/core_ext/date'

      def generate!(month = nil, year = nil)
        # asks for a new remote report to generated
        # this also clears any old reports on the server
        chibi_client.create_remote_report(month || time_last_month.month, year || time_last_month.year)
      end

      private

      def chibi_client
        @chibi_client ||= ChibiClient.new
      end

      def time_last_month
        @time_last_month ||= 1.month.ago
      end
    end
  end
end
