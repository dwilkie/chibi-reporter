require 'spec_helper'
require './lib/chibi/reporter/report_mailer'

module Chibi
  module Reporter
    describe ReportMailer do
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

          last_mail.from.should == [sender]
          last_mail.to.should == recipients
          last_mail.cc.should == cc
          last_mail.bcc.should == bcc
          last_mail.subject.should == mail_subject
          last_mail.text_part.decoded.should == body
          attachment = last_mail.attachments[0]
          attachment.filename.should == filename
        end
      end
    end
  end
end
