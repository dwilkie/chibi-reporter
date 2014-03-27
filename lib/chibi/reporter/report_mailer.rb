module Chibi
  module Reporter
    class ReportMailer
      require_relative './config/mail'

      def deliver_mail(file, options)
        filename = File.basename(options[:filename])
        Mail.deliver do
          attachments[filename] = {:content => Base64.encode64(file.read), :encoding => 'base64'}
          subject(options[:subject])
          from(options[:sender])
          to(options[:recipients])
          cc(options[:cc])
          bcc(options[:bcc])
          text_part do
            body(options[:body])
          end
        end
      end
    end
  end
end
