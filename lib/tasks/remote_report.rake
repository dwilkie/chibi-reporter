require './lib/chibi/reporter/remote_report'

namespace :chibi do
  namespace :reporter do
    namespace :remote_report do
      desc "Generates a remote report for the previous month"
      # run this once a month
      task :generate do
        Chibi::Reporter::RemoteReport.new.generate!
      end
    end
  end
end
