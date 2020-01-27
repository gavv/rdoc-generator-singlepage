lib = File.expand_path('lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name        = 'rdoc-generator-solarfish'
  spec.version     = '0.0.3'
  spec.authors     = ['Victor Gaydov', 'Dmitriy Shilin', 'Valeria Khomyakova']
  spec.email       = ['victor@enise.org']
  spec.description = 'Single-page HTML5 generator for Ruby RDoc'
  spec.summary     = 'Exposes a new HTML formatter for RDoc'
  spec.homepage    = 'https://github.com/rbdoc/rdoc-generator-solarfish'
  spec.license     = 'MIT'

  spec.files         = `git ls-files`.split
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.3'

  spec.add_runtime_dependency 'rdoc', '>= 5.1'
  spec.add_runtime_dependency 'sass', '~> 3.4'
  spec.add_runtime_dependency 'slim', '~> 3.0'
  spec.add_runtime_dependency 'recursive-open-struct', '~> 1.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '>= 12.0'
  spec.add_development_dependency 'rubocop', '~> 0.49'
  spec.add_development_dependency 'minitest', '~> 5.10'
  spec.add_development_dependency 'html5_validator', '~> 1.0'
end
