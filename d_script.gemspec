# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'd_script/version'

Gem::Specification.new do |spec|
  spec.name          = "d_script"
  spec.version       = DScript::VERSION
  spec.authors       = ["Dan McAulay"]
  spec.email         = ["dmcaulay@gmail.com"]
  spec.description   = %q{run distributed scripts using rake and redis}
  spec.summary       = %q{run distributed scripts using rake and redis}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"

  ["rake", "rspec"].each do |dep|
    spec.add_development_dependency dep
  end

  ["redis", "slop"].each do |dep|
    spec.add_runtime_dependency dep
  end
end
