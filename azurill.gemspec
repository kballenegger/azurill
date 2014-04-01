# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'azurill/version'

Gem::Specification.new do |gem|
  gem.name          = 'azurill'
  gem.version       = Azurill::VERSION
  gem.authors       = ['Kenneth Ballenegger']
  gem.email         = ['kenneth@ballenegger.com']
  gem.description   = %q{A portable CLI execution log viewer.}
  gem.summary       = %q{A portable CLI execution log viewer.}
  gem.homepage      = 'https://github.com/kballenegger/azurill'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_runtime_dependency 'ffi-ncurses'
  gem.add_runtime_dependency 'zmq'
end
