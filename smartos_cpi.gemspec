# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'smartos/cloud'

Gem::Specification.new do |gem|
  gem.name          = "smartos_cpi"
  gem.version       = SmartOS::Cloud::VERSION
  gem.authors       = ["Martin Englund"]
  gem.email         = ["martin@englund.nu"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "bosh_cpi", "~>0.5"
end
