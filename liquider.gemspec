# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'liquider/version'

Gem::Specification.new do |spec|
  spec.name          = "liquider"
  spec.version       = Liquider::VERSION
  spec.authors       = ["Simon Génier"]
  spec.email         = ["simon.genier@jadedpixel.com"]
  spec.summary       = %q{An experimental implementation of the Liquid templating language}
  spec.description   = <<-DESCRIPTION
  Liquider is an implementation of the Liquid templating language that aims at
  improving error reporting and performances.
  DESCRIPTION
  spec.homepage      = "https://github.com/sgnr/Liquider"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
end
