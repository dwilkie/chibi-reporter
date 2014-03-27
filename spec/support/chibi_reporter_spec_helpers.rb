require_relative './web_mock'

module ChibiReporterSpecHelpers
  include WebMockHelpers

  private

  def sample_remote_report
    @sample_remote_report ||= YAML.load_file(
      File.join(File.dirname(__FILE__), "./sample_remote_report.yaml")
    )
  end

  def expect_external_request(cassette, options = {}, &block)
    VCR.use_cassette(cassette, options) { yield }
  end

  def all_operators
    {:kh => [:smart, :beeline, :qb, :cootel]}
  end

  def mime_type
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  end

  def operator_enabled?(country_code, operator_id)
    env_config(:enabled, country_code, operator_id).to_i == 1
  end

  def force_generate?(country_code, operator_id)
    env_config(:force_generate, country_code, operator_id).to_i == 1
  end

  def email_enabled?(country_code, operator_id)
    env_config(:email_enabled, country_code, operator_id).to_i == 1
  end

  def asserted_operators(options = {})
    asserted_operators = {}
    all_operators.each do |country_code, operator_ids|
      asserted_operators[country_code] = []
      operator_ids.each do |operator_id|
        enabled = operator_enabled?(country_code, operator_id)
        options.each do |criterion, value|
          enabled &&= send("#{criterion}?", country_code, operator_id) if value
        end
        asserted_operators[country_code] << operator_id if enabled
      end
    end

    asserted_operators
  end

  def with_asserted_operators(options = {}, &block)
    index = 0
    asserted_operators(options).each do |country_code, operator_ids|
      operator_ids.each do |operator_id|
        yield country_code, operator_id, index
        index += 1
      end
    end
  end

  def report_file_extension
    "xlsx"
  end

  def operator_suggested_filename(year, month, country_code, operator_id)
    basename = report_name(year, month, country_code, operator_id)
    month_dir = Time.new(year, month).strftime("%m_%B")
    "#{year}/#{month_dir}/#{basename}.#{report_file_extension}".gsub(/[^\w\.\/]/, " ").gsub(/\s+/, "_").downcase
  end

  def google_drive_root_directory(country_code, operator_id)
    env_config(:google_drive_root_directory_id, country_code, operator_id)
  end

  def aws_s3_root_directory(country_code, operator_id)
    File.join(*concatenated_configuration(country_code, operator_id, :aws_s3_root_directory).reverse)
  end

  def mail_subject(year, month, country_code, operator_id)
    report_name(year, month, country_code, operator_id)
  end

  def mail_body(year, month, country_code, operator_id)
    body = []
    body << env_config(:mail_recipient_names, country_code, operator_id)
    body << business_name(country_code)
    body << invoice_period(year, month)
    body << env_config(:mail_sender_signature, country_code, operator_id)
    body << operator_id
    body.join(", ")
  end

  def mail_recipients(country_code, operator_id)
    concatenated_configuration(country_code, operator_id, :mail_recipients).join(";").split(";")
  end

  def mail_cc(country_code, operator_id)
    concatenated_configuration(country_code, operator_id, :mail_cc).join(";").split(";")
  end

  def mail_bcc(country_code, operator_id)
    concatenated_configuration(country_code, operator_id, :mail_bcc).join(";").split(";")
  end

  def mail_sender(country_code, operator_id)
    env_config(:mail_sender, country_code, operator_id)
  end

  def report_name(year, month, country_code, operator_id)
    business_name = business_name(country_code)
    operator_human_name = env_config(:human_name, country_code, operator_id)

    text = []
    text << operator_human_name
    text << "-"
    text << business_name
    text << "Invoice and Report"
    text << invoice_period(year, month)
    text.join(" ")
  end

  def invoice_period(year, month)
    Time.new(year, month).strftime("%B %Y")
  end

  def business_name(country_code)
    env_config(:business_name, country_code)
  end

  def concatenated_configuration(country_code, operator_id, key)
    normalized_key = key.to_s.upcase
    normalized_country_code = country_code.to_s.upcase
    normalized_operator_id = operator_id.to_s.upcase
    configuration = []
    configuration << env_config(key, country_code, operator_id)
    configuration << env_config(key, country_code)
    configuration << env_config(key)
    configuration << ENV["CHIBI_REPORTER_REPORT_#{normalized_key}"]
    configuration.compact
  end

  def env_config(key, country_code = nil, operator_id = nil)
    normalized_operator_id = operator_id.to_s.upcase
    normalized_country_code = country_code.to_s.upcase
    normalized_key = key.upcase
    keys = ["CHIBI_REPORTER_REPORT_OPERATOR"]
    keys << normalized_country_code unless country_code.nil?
    keys << normalized_operator_id unless operator_id.nil?
    keys << normalized_key
    ENV[keys.join("_")]
  end

  module ChibiClient
    include ChibiReporterSpecHelpers

    private

    def chibi_client_remote_report_uri
      URI.parse(ENV['CHIBI_REPORTER_CLIENT_REMOTE_REPORT_URL'])
    end

    def expect_chibi_client_remote_report_request(cassette, options = {}, &block)
      options[:erb] = {
        :chibi_client_remote_report_url => chibi_client_remote_report_uri.to_s
      }.merge(options[:erb] || {})
      expect_external_request(cassette, options, &block)
    end

    def assert_chibi_client_remote_report_request(method)
      first_request(:method).should == method
      uri = first_request.uri
      uri.user.should == chibi_client_remote_report_uri.user
      uri.password.should == chibi_client_remote_report_uri.password
      uri.path.should == chibi_client_remote_report_uri.path
    end

    def expect_chibi_client_get_remote_report(cassette = nil, options = {}, &block)
      cassette ||= :chibi_client_get_remote_report
      options[:erb] = {
        :report => sample_remote_report.to_json
      }.merge(options[:erb] || {})
      expect_chibi_client_remote_report_request(cassette, options, &block)
    end

    def expect_chibi_client_create_remote_report(&block)
      expect_chibi_client_remote_report_request(:chibi_client_create_remote_report, &block)
    end
  end

  module Aws
    module S3Client
      include ChibiReporterSpecHelpers

      private

      def aws_s3_metadata_url
        aws_s3_url(ENV['CHIBI_REPORTER_AWS_S3_METADATA_FILE'])
      end

      def aws_s3_url(key)
        path = aws_s3_object_key(key)
        "https://#{ENV['AWS_S3_BUCKET']}.s3.amazonaws.com/#{path}"
      end

      def aws_s3_object_key(key)
        File.join(ENV['CHIBI_REPORTER_AWS_S3_ROOT_DIRECTORY'], key)
      end

      def aws_s3_upload_erb(options = {})
        upload_urls = []
        options[:files].each do |file|
          upload_urls << {
            :url => aws_s3_url(File.join(file[:root_directory], file[:filename]))
          }
        end
        {:aws_s3_upload_urls => upload_urls}
      end
    end
  end

  module Google
    module DriveClient
      include ChibiReporterSpecHelpers

      private

      def google_drive_upload_erb(options = {})
        upload_urls = []
        options[:files].each do |file|
          parent_directories = File.dirname(file[:filename]).split("/")
          root_directory = file[:root_directory]
          parent_directories.each do |parent_directory|
            url = google_drive_find_directory_url(parent_directory, root_directory)
            root_directory = parent_directory
            upload_urls << {
              :url => url,
              :method => :get,
              :result => root_directory
            }
          end

          upload_urls << {
            :url => google_drive_upload_file_url,
            :method => google_drive_upload_file_method,
            :location => google_drive_upload_file_url(:upload_id => true)
          }

          upload_urls << {
            :url => google_drive_upload_file_url(:upload_id => true),
            :method => google_drive_upload_file_method,
            :result => file[:upload_result] || "result"
          }
        end
        {
          :google_oauth_url => google_oauth_url,
          :google_drive_upload_urls => upload_urls
        }
      end

      def google_drive_find_directory_url(title, parent_directory)
        "https://www.googleapis.com/drive/v2/files?q=mimeType='#{google_drive_folder_mime_type}'%20AND%20trashed=false%20AND%20title='#{title}'%20AND%20'#{parent_directory}'%20in%20parents"
      end

      def google_drive_folder_mime_type
        "application/vnd.google-apps.folder"
      end

      def google_oauth_url
        "https://accounts.google.com/o/oauth2/token"
      end

      def google_drive_upload_file_url(options = {})
        base_url = "https://www.googleapis.com/upload/drive/v2/files?alt=json&uploadType=resumable"
        base_url << "&upload_id=upload_id" if options[:upload_id]
        base_url
      end

      def google_drive_upload_file_method
        :post
      end
    end
  end

  module MailAssertions
    private

    def mail_deliveries
      Mail::TestMailer.deliveries
    end

    def last_mail
      mail_deliveries.last
    end
  end

  module Report
    module Operator
      include ChibiReporterSpecHelpers

      private

      def sample_operator_report(country_code, operator_id)
        sample_remote_report["report"]["countries"][country_code.to_s]["operators"][operator_id.to_s]
      end

      shared_examples_for "an operator report" do
        let(:year) { 2014 }
        let(:month) { 3 }

        subject {
          operator_class.new(
            :data => sample_operator_report, :month => month, :year => year, :invoice_number => 1
          )
        }

        describe ".enabled?" do
          it "should return whether or not this report is enabled" do
            result = subject.class.enabled?
            result.should_not be_nil
            result.should == operator_enabled?
          end
        end

        describe "#email_enabled?" do
          it "should return whether or not this report has email enabled" do
            result = subject.email_enabled?
            result.should_not be_nil
            result.should == email_enabled?
          end
        end

        describe "#force_generate?" do
          it "should return whether or not this report should be force generated" do
            result = subject.force_generate?
            result.should_not be_nil
            result.should == force_generate?
          end
        end

        describe "#generate!" do
          it "should create a report and return a string IO" do
            result = subject.generate!
            result.should be_a(StringIO)
          end
        end

        describe "#io_stream" do
          it "should always return a rewinded StringIO" do
            subject.generate!
            2.times do
              result = subject.io_stream
              result.should be_a(StringIO)
              result.should_not be_eof
              result.read
              result.should be_eof
            end
          end
        end

        describe "#suggested_filename" do
          it "should return a filename and path which includes the operator's name, our business name and report period" do
            result = subject.suggested_filename
            result.should_not be_nil
            result.should == operator_suggested_filename(year, month)
          end
        end

        describe "#mime_type" do
          it "should return the correct mime type" do
            result = subject.mime_type
            result.should_not be_nil
            result.should == mime_type
          end
        end

        describe "#google_drive_root_directory_id" do
          it "should return google drive root directory id" do
            result = subject.google_drive_root_directory_id
            result.should_not be_nil
            result.should == google_drive_root_directory
          end
        end

        describe "#aws_s3_root_directory" do
          it "should return the aws s3 root directory" do
            result = subject.aws_s3_root_directory
            result.should_not be_nil
            result.should == aws_s3_root_directory
          end
        end

        describe "#mail_subject" do
          it "should return an email subject line" do
            result = subject.mail_subject
            result.should_not be_nil
            result.should == mail_subject(year, month)
          end
        end

        describe "#mail_recipients" do
          it "should return a list of mail recipients" do
            result = subject.mail_recipients
            result.should_not be_empty
            result.should == mail_recipients
          end
        end

        describe "#mail_cc" do
          it "should return a list of cc recipients" do
            result = subject.mail_cc
            result.should_not be_empty
            result.should == mail_cc
          end
        end

        describe "#mail_bcc" do
          it "should return a list of bcc recipients" do
            result = subject.mail_bcc
            result.should_not be_empty
            result.should == mail_bcc
          end
        end

        describe "#mail_sender" do
          it "should return the mail sender" do
            result = subject.mail_sender
            result.should_not be_nil
            result.should == mail_sender
          end
        end

        describe "#mail_body" do
          it "should return the mail body" do
            result = subject.mail_body
            result.should_not be_nil
            result.should == mail_body(year, month)
          end
        end
      end

      module Kh
        include ChibiReporterSpecHelpers::Report::Operator

        private

        def country_code
          :kh
        end

        def sample_operator_report
          super(country_code, operator_id)
        end

        def operator_enabled?
          super(country_code, operator_id)
        end

        def email_enabled?
          super(country_code, operator_id)
        end

        def force_generate?
          super(country_code, operator_id)
        end

        def google_drive_root_directory
          super(country_code, operator_id)
        end

        def aws_s3_root_directory
          super(country_code, operator_id)
        end

        def mail_recipients
          super(country_code, operator_id)
        end

        def mail_cc
          super(country_code, operator_id)
        end

        def mail_bcc
          super(country_code, operator_id)
        end

        def mail_sender
          super(country_code, operator_id)
        end

        def mail_body(year, month)
          super(year, month, country_code, operator_id)
        end

        def mail_subject(year, month)
          super(year, month, country_code, operator_id)
        end

        def operator_suggested_filename(year, month)
          super(year, month, country_code, operator_id)
        end
      end
    end
  end
end
