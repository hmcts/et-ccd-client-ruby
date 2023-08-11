require "bundler/setup"
require "et_ccd_client"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  Dir.glob(File.absolute_path(File.join('.', 'support', '**', '*.rb'), __dir__)).sort.each { |f| require f }
end
