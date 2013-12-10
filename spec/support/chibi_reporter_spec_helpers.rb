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

  def operator_enabled?(country_code, operator_id)
    ENV["CHIBI_REPORTER_REPORT_OPERATOR_#{country_code.to_s.upcase}_#{operator_id.to_s.upcase}_ENABLED"].to_i == 1
  end

  def asserted_operators
    return @asserted_operators if @asserted_operators
    @asserted_operators = {}
    all_operators.each do |country_code, operator_ids|
      @asserted_operators[country_code] = []
      operator_ids.each do |operator_id|
        @asserted_operators[country_code] << operator_id if operator_enabled?(country_code, operator_id)
      end
    end

    @asserted_operators
  end

  def report_file_extension
    "xlsx"
  end

  def operator_suggested_filename(year, month, country_code, operator_id)
    business_name = ENV["CHIBI_REPORTER_REPORT_OPERATOR_#{country_code.upcase}_BUSINESS_NAME"].gsub(/\s+/, "_").downcase
    operator_human_name = ENV["CHIBI_REPORTER_REPORT_OPERATOR_#{country_code.to_s.upcase}_#{operator_id.to_s.upcase}_HUMAN_NAME"]
    "#{year}/#{month}/#{operator_human_name}_#{business_name}_invoice_and_report_january_2014.#{report_file_extension}"
  end

  def google_drive_root_directory(country_code, operator_id)
    ENV["CHIBI_REPORTER_REPORT_OPERATOR_#{country_code.to_s.upcase}_#{operator_id.to_s.upcase}_GOOGLE_DRIVE_ROOT_DIRECTORY_ID"]
  end

  def aws_s3_root_directory(country_code, operator_id)
    File.join(
      ENV["CHIBI_REPORTER_REPORT_AWS_S3_ROOT_DIRECTORY"],
      ENV["CHIBI_REPORTER_REPORT_OPERATOR_AWS_S3_ROOT_DIRECTORY"],
      ENV["CHIBI_REPORTER_REPORT_OPERATOR_#{country_code.to_s.upcase}_AWS_S3_ROOT_DIRECTORY"],
      ENV["CHIBI_REPORTER_REPORT_OPERATOR_#{country_code.to_s.upcase}_#{operator_id.to_s.upcase}_AWS_S3_ROOT_DIRECTORY"]
    )
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
            :url => "https://www.googleapis.com/upload/drive/v2/files?alt=json&uploadType=multipart",
            :method => :post,
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
        subject { operator_class.new(:data => sample_operator_report, :month => 1, :year => 2014, :invoice_number => 1) }

        describe "#generate!" do
          it "should create a report and return a string IO" do
            subject.generate!.should be_a(StringIO)
          end
        end

        describe "#suggested_filename" do
          it "should return a filename and path which includes the operator's name, our business name and report period" do
            subject.suggested_filename.should == operator_suggested_filename(2014, "01_january")
          end
        end

        describe "#mime_type" do
          it "should return the correct mime type" do
            subject.mime_type.should == mime_type
          end
        end

        describe "#google_drive_root_directory_id" do
          it "should return google drive root directory id" do
            subject.google_drive_root_directory_id.should == google_drive_root_directory
          end
        end

        describe "#aws_s3_root_directory" do
          it "should return the aws s3 root directory" do
            subject.aws_s3_root_directory.should == aws_s3_root_directory
          end
        end

        describe ".enabled?" do
          it "should return whether or not this report is enabled" do
            subject.class.enabled?.should == operator_enabled?
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

        def mime_type
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        end

        def operator_enabled?
          super(country_code, operator_id)
        end

        def google_drive_root_directory
          super(country_code, operator_id)
        end

        def aws_s3_root_directory
          super(country_code, operator_id)
        end

        def operator_suggested_filename(year, month)
          super(year, month, country_code, operator_id)
        end
      end
    end
  end
end
