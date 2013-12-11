require 'mail'

RSpec.configure do |config|
  config.before do
    Mail.defaults do
      delivery_method(:test)
    end
    Mail::TestMailer.deliveries.clear
  end
end
