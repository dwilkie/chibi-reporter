require './app/models/report/cambodia/smart'

namespace :report do
  desc "Fetches the latest data and saves it to S3"
  task :generate do
    Report::Chibi.new.generate!
  end
end
