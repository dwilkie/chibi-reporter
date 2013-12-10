require './lib/chibi/reporter/report_generator'

namespace :chibi do
  namespace :reporter do
    namespace :report_generator do
      desc "Generates customizable reports for Chibi"
      # run this after calling rake chibi:reporter:remote_report:generate
      task :run do
        Chibi::Reporter::ReportGenerator.run!
      end
    end
  end
end
