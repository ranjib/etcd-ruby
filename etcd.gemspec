# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'etcd/version'

Gem::Specification.new do |spec|
  spec.name          = "etcd"
  spec.version       = Etcd::VERSION
  spec.authors       = ["Ranjib Dey"]
  spec.email         = ["ranjib@pagerduty.com"]
  spec.description   = %q{Ruby client library for etcd}
  spec.summary       = spec.description
  spec.homepage      = "https://github.com/ranjib/etcd-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  # Support enterprise distros, such as el6.
  spec.required_ruby_version = ">= 1.8.7"

  spec.add_dependency "mixlib-log"

  if RUBY_VERSION < "1.9"
    spec.add_development_dependency "celluloid", "< 0.15"
  else
    spec.add_development_dependency "coco"
    spec.add_development_dependency "rubocop"
  end

  spec.add_development_dependency "uuid"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rdoc"
  spec.add_development_dependency "rspec"
end
