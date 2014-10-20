# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'celltrust/version'

Gem::Specification.new do |spec|
  spec.name          = "celltrust"
  spec.version       = Celltrust::VERSION
  spec.authors       = ["Ronaldo Raivil"]
  spec.email         = ["raivil@gmail.com"]
  spec.summary       = "A Ruby wrapper for the Celltrust API"
  spec.description   = "See description"
  spec.homepage      = "http://github.com/raivil/celltrust"
  spec.license       = "GPL-3.0"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'savon', '~> 2.0'
  spec.add_dependency 'engtagger'

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'webmock'
end
