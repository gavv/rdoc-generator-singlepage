lib = File.expand_path('lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name        = 'rdoc-generator-singlepage'
  spec.version     = '0.0.1'
  spec.authors     = ['Victor Gaydov', 'Dmitriy Shilin', 'Valeria Khomyakova']
  spec.email       = ['victor@enise.org']
  spec.description = 'Single page HTML5 generator for Ruby RDoc'
  spec.summary     = 'Exposes a new HTML formatter for RDoc'
  spec.homepage    = 'https://github.com/rbdoc/rdoc-generator-singlepage'
  spec.license     = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'rdoc'
  spec.add_runtime_dependency 'builder'
  spec.add_runtime_dependency 'sass'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
end
