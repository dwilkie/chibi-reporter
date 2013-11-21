require './lib/chibi/reporter/report/remote'

namespace :chibi do
  namespace :reporter do
    namespace :report do
      namespace :remote do
        desc "Generates a remote report for the previous month"
        # run this once a month
        task :generate do
          Chibi::Reporter::Report::Remote.new.generate!
        end
      end

      desc "Processes the generated report"
      # run this after generating a remote report
      task :process do
        Chibi::Reporter::Report::Remote.process!
      end
    end
  end
end
