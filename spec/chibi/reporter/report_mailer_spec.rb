require 'spec_helper'
require './lib/chibi/reporter/report_mailer'

module Chibi
  module Reporter
    describe ReportMailer do
      include ChibiReporterSpecHelpers
      include ChibiReporterSpecHelpers::MailAssertions

      describe "#deliver_mail(file, options)" do
        let(:file) { StringIO.new(file_contents) }
        let(:file_contents) { "foo" }

        let(:filename) { "foo.xlsx" }
        let(:sender) { "sender@example.com" }
        let(:recipients) { ["recipient1@example.com"] }
        let(:cc) { ["cc1@example.com"] }
        let(:bcc) { ["bcc1@example.com"] }
        let(:mail_subject) { "mail_subject" }
        let(:body) { "body" }

        it "should deliver a mail and attach the given file" do
          subject.deliver_mail(
            file,
            :filename => filename,
            :sender => sender,
            :recipients => recipients,
            :cc => cc,
            :bcc => bcc,
            :subject => mail_subject,
            :body => body
          )

          expect(last_mail.from).to eq([sender])
          expect(last_mail.to).to eq(recipients)
          expect(last_mail.cc).to eq(cc)
          expect(last_mail.bcc).to eq(bcc)
          expect(last_mail.subject).to eq(mail_subject)
          expect(last_mail.text_part.decoded).to eq(body)
          attachment = last_mail.attachments[0]
          expect(attachment.body.decoded).to eq(file_contents)
          expect(attachment.filename).to eq(filename)
          expect(attachment.content_transfer_encoding).to eq("base64")
          expect(attachment.mime_type).to eq(mime_type)
        end
      end
    end
  end
end
