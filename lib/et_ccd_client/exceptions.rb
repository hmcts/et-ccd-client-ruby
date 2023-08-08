require 'et_ccd_client/exceptions/base'
Dir.glob(File.absolute_path(File.join('.', 'exceptions', '**', "*.rb"), __dir__)).sort.each { |f| require f }
