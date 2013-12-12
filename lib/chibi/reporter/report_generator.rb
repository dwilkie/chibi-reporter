module Chibi
  module Reporter
    class ReportGenerator
      require_relative "./chibi_client"
      require_relative "./aws/s3_client"
      require_relative "./google/drive_client"
      require_relative "./report_mailer"

      Dir[File.join(File.dirname(__FILE__), '**/*.rb')].each { |file| require file }

      REPORTS_KEY = "reports"
      OPERATOR_KEY = "operator"
      LAST_INVOICE_NUMBER_KEY = "last_invoice_number"

      attr_accessor :invoice_number

      def run!
        raise("remote report not yet available") unless remote_report
        self.invoice_number = reports_operator_metadata[LAST_INVOICE_NUMBER_KEY].to_i

        with_operator_reports do |operator_report|
          next if operator_reports_exist? && !operator_report.force_generate?
          operator_report.generate!
          distribute(operator_report)
          self.invoice_number += 1
        end

        write_reports_operator_metadata unless operator_reports_exist?
      end

      private

      def distribute(operator_report)
        email(operator_report) if !operator_reports_exist? && operator_report.email_enabled?
        upload_to_s3(operator_report)
        upload_to_google_drive(operator_report)
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

      def operator_reports_exist?
        (reports_operator_metadata[year.to_s] || {})[month.to_s]
      end

      def metadata
        @metadata ||= JSON.parse(metadata_file.read)
      end

      def reports_metadata
        metadata[REPORTS_KEY] || {}
      end

      def reports_operator_metadata
        reports_metadata[OPERATOR_KEY] || {}
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

      def write_reports_operator_metadata
        metadata_file.write(
          metadata.deep_merge(
            REPORTS_KEY => {
              OPERATOR_KEY => {
                LAST_INVOICE_NUMBER_KEY => invoice_number,
                year => {month => Time.current}
              }
            }
          ).to_json
        )
      end
    end
  end
end
