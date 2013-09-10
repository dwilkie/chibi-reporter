module ChibiReportHelpers
  def sample_remote_report
    @sample_remote_report ||= YAML.load_file(
      File.join(File.dirname(__FILE__), "./sample_remote_report.yaml")
    )
  end

  def sample_operator_report(country_code, operator_id)
    sample_remote_report["report"]["countries"][country_code.to_s]["operators"][operator_id.to_s]
  end
end
