require './app/models/report/chibi'

namespace :report do
  namespace :remote do
    desc "Generates a remote report for the previous month"
    # run this once a month
    task :generate do
      Report::Chibi.new.generate!
    end
  end

  desc "Processes the generated report"
  # run this after generating a remote report
  task :process do
    Report::Chibi.process!
  end
end
