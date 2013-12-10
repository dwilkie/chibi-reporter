module Chibi
  module Reporter
    class ReportGenerator
      require_relative "./chibi_client"
      require_relative "./aws/s3_client"
      require_relative "./google/drive_client"

      Dir[File.join(File.dirname(__FILE__), '**/*.rb')].each { |file| require file }

      LAST_INVOICE_NUMBER_KEY = "last_invoice_number"

      attr_accessor :month, :year, :invoice_number, :report_data

      def run!
        return unless remote_report
        self.report_data = remote_report["report"]
        self.month = report_data["month"]
        self.year = report_data["year"]
        self.invoice_number = metadata[LAST_INVOICE_NUMBER_KEY].to_i
        report_data["countries"].each do |country_code, country_data|
          country_data["operators"].each do |operator, operator_data|
            if operator_report = operator_report(country_code, operator, operator_data)
              operator_report.generate!
              google_drive_client.upload(
                operator_report.io_stream,
                :filename => operator_report.suggested_filename,
                :mime_type => operator_report.mime_type,
                :root_directory => operator_report.google_drive_root_directory_id
              )

              # upload_report_to_s3
              # upload report to google drive
              # email the report to relevant parties if applicable
              #package.serialize("#{name}_#{business_name.gsub(/\s+/, '_').downcase}_invoice_report_#{invoice_period.gsub(/\s+/, '_').downcase}.xlsx")
              self.invoice_number += 1
            end
          end
        end
        write_invoice_number if increment_invoice_number?
      end

      private

      def operator_report(country_code, operator, operator_data)
        operator_report_path = "operator/#{country_code}/#{operator}"
        if File.exists?(File.expand_path("./report/#{operator_report_path}.rb", File.dirname(__FILE__)))
          "chibi/reporter/report/#{operator_report_path}".classify.constantize.new(
            :data => operator_data,
            :month => month,
            :year => year,
            :invoice_number => invoice_number + 1
          )
        end
      end

      def metadata
        @metadata ||= JSON.parse(metadata_file.read)
      end

      def metadata_file
        @metadata_file ||= s3_client.metadata_file
      end

      def s3_client
        @s3_client ||= Aws::S3Client.new
      end

      def remote_report
        @remote_report ||= chibi_client.get_remote_report
      end

      def chibi_client
        @chibi_client ||= ChibiClient.new
      end

      def google_drive_client
        @google_drive_client ||= Google::DriveClient.new
      end

      def increment_invoice_number?
        ENV["CHIBI_REPORTER_REPORT_GENERATOR_INCREMENT_INVOICE_NUMBER"].to_i == 1
      end

      def write_invoice_number
        metadata_file.write(metadata.merge(LAST_INVOICE_NUMBER_KEY => invoice_number).to_json)
      end
    end
  end
end
