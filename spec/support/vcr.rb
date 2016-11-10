require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = File.expand_path(File.join(File.dirname(__FILE__), "..", "fixtures/vcr_cassettes"))
  c.hook_into :webmock
  c.debug_logger = File.open("vcr_debugger.txt", 'w')
end
