# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rubykon/version'

Gem::Specification.new do |spec|
  spec.name          = "rubykon"
  spec.version       = Rubykon::VERSION
  spec.authors       = ["Tobias Pfeiffer"]
  spec.email         = ["pragtob@gmail.com"]

  spec.summary       = %q{An AI to play Go using Monte Carlo Tree Search.}
  spec.description   = %q{An AI to play Go using Monte Carlo Tree Search. Currently includes the mcts gem and benchmark/avg. Works on all major ruby versions.}
  spec.homepage      = "https://github.com/PragTob/rubykon"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
