require 'mail'
require 'recipient_interceptor'

Mail.register_interceptor(
  RecipientInterceptor.new(ENV['RECIPIENT_INTERCEPTOR_EMAIL'])
) unless ENV["RECIPIENT_INTERCEPTOR_ENABLED"].to_i == 0

Mail.defaults do
  delivery_method(
    :smtp,
    :address => 'smtp.gmail.com',
    :port => '587',
    :user_name => ENV["GMAIL_USER_NAME"],
    :password => ENV["GMAIL_PASSWORD"],
    :authentication => :plain,
    :enable_starttls_auto => true
  )
end
