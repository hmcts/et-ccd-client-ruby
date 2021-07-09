
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "et_ccd_client/version"

Gem::Specification.new do |spec|
  spec.name          = "et_ccd_client"
  spec.version       = EtCcdClient::VERSION
  spec.authors       = ["Gary Taylor"]
  spec.email         = ["gary.taylor@hmcts.net"]

  spec.summary       = %q{A client to communicate with the employment tribunals CCD system}
  spec.description   = %q{This client implements methods to call the relevant CCD endpoints for the employment tribunals CCD system}
  spec.homepage      = "https://github.com/hmcts/et-ccd-client-ruby"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'addressable', '~> 2.6'
  spec.add_dependency 'rest-client', '~> 2.0', '>= 2.0.2'
  spec.add_dependency 'webmock', '~> 3.6'
  spec.add_dependency 'rotp', '~> 6.2'
  spec.add_dependency 'connection_pool', '~> 2.2', '>= 2.2.2'
  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency 'rubocop', '~> 0.71.0'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.33'
  spec.add_development_dependency 'rack', '~> 2.0', '>= 2.0.7'
end
