module ChibiReportHelpers
  private

  def sample_remote_report
    @sample_remote_report ||= YAML.load_file(
      File.join(File.dirname(__FILE__), "./sample_remote_report.yaml")
    )
  end

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

    describe "#filename" do
      it "should return a filename which includes the operator id, business name and report period" do
        subject.filename.should == "#{operator_id}_#{asserted_business_name}_invoice_and_report_january_2014.#{asserted_file_extension}"
      end
    end

    describe "#mime_type" do
      it "should return the correct mime type" do
        subject.mime_type.should == asserted_mime_type
      end
    end

    describe "#year_directory" do
      it "should return the year" do
        subject.year_directory.should == 2014
      end
    end

    describe "#month_directory" do
      it "should return the month as a directory name" do
        subject.month_directory.should == "01_january"
      end
    end

    describe "#google_drive_parent_directory_id" do
      it "should return google drive parent directory id" do
        subject.google_drive_parent_directory_id.should == asserted_google_drive_parent_directory_id
      end
    end
  end

  module Kh
    include ChibiReportHelpers

    private

    def sample_operator_report
      super(:kh, operator_id)
    end

    def asserted_mime_type
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    end

    def asserted_file_extension
      "xlsx"
    end

    def asserted_google_drive_parent_directory_id
      ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_#{operator_id.to_s.upcase}_GOOGLE_DRIVE_PARENT_DIRECTORY_ID"]
    end

    def asserted_business_name
      ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_BUSINESS_NAME"].gsub(/\s+/, "_").downcase
    end
  end
end
