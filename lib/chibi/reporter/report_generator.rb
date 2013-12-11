module Chibi
  module Reporter
    class ReportGenerator
      require_relative "./chibi_client"
      require_relative "./aws/s3_client"
      require_relative "./google/drive_client"
      require_relative "./report_mailer"

      Dir[File.join(File.dirname(__FILE__), '**/*.rb')].each { |file| require file }

      LAST_INVOICE_NUMBER_KEY = "last_invoice_number"

      attr_accessor :invoice_number

      def run!
        return unless remote_report

        self.invoice_number = metadata[LAST_INVOICE_NUMBER_KEY].to_i
        with_operator_reports do |operator_report|
          operator_report.generate!
          distribute(operator_report)
          self.invoice_number += 1
        end

        write_invoice_number if increment_invoice_number?
      end

      private

      def distribute(operator_report)
        upload_to_s3(operator_report)
        upload_to_google_drive(operator_report)
        email(operator_report)
      end

      def upload_to_s3(operator_report)
        s3_client.upload(
          operator_report.io_stream,
          :filename => operator_report.suggested_filename,
          :root_directory => operator_report.aws_s3_root_directory
        )
      end

      def upload_to_google_drive(operator_report)
        google_drive_client.upload(
          operator_report.io_stream,
          :filename => operator_report.suggested_filename,
          :mime_type => operator_report.mime_type,
          :root_directory => operator_report.google_drive_root_directory_id
        )
      end

      def email(operator_report)
        report_mailer.deliver_mail(
          operator_report.io_stream,
          :filename => operator_report.suggested_filename,
          :subject => operator_report.mail_subject,
          :recipients => operator_report.mail_recipients,
          :cc => operator_report.mail_cc,
          :bcc => operator_report.mail_bcc,
          :sender => operator_report.mail_sender,
          :body => operator_report.mail_body
        )
      end

      def with_operator_reports(&block)
        report_data["countries"].each do |country_code, country_data|
          country_data["operators"].each do |operator, operator_data|
            if operator_report = operator_report(country_code, operator, operator_data)
              yield operator_report
            end
          end
        end
      end

      def operator_report(country_code, operator, operator_data)
        operator_report_path = "operator/#{country_code}/#{operator}"
        return unless File.exists?(
          File.expand_path("./report/#{operator_report_path}.rb", File.dirname(__FILE__))
        )
        operator_report_class = "chibi/reporter/report/#{operator_report_path}".classify.constantize
        return unless operator_report_class.enabled?
        operator_report_class.new(
          :data => operator_data,
          :month => month,
          :year => year,
          :invoice_number => invoice_number + 1
        )
      end

      def report_data
        remote_report["report"]
      end

      def month
        report_data["month"]
      end

      def year
        report_data["year"]
      end

      def metadata
        @metadata ||= JSON.parse(metadata_file.read)
      end

      def metadata_file
        @metadata_file ||= s3_client.metadata_file
      end

      def remote_report
        @remote_report ||= chibi_client.get_remote_report
      end

      def chibi_client
        @chibi_client ||= ChibiClient.new
      end

      def s3_client
        @s3_client ||= Aws::S3Client.new
      end

      def google_drive_client
        @google_drive_client ||= Google::DriveClient.new
      end

      def report_mailer
        @report_mailer ||= ReportMailer.new
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
