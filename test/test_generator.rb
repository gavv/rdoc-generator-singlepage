require 'html5_validator/validator'
require 'pp'
require 'json'

require 'minitest'
require 'minitest/autorun'

require 'rdoc/rdoc'
require 'rdoc/generator/solarfish'

require_relative 'themes'

class TestGenerator < MiniTest::Test
  def source_file
    File.join(File.dirname(__FILE__), '../docs/example.rb')
  end

  def run_generator(file, title)
    dir = File.join(Dir.mktmpdir, 'out')

    options = RDoc::Options.new
    options.setup_generator 'solarfish'

    options.verbosity = 0
    options.files = [file]
    options.op_dir = dir
    options.title = title

    options.sf_htmlfile = 'test.html'
    options.sf_jsonfile = 'test.json'

    yield options if block_given?

    rdoc = RDoc::RDoc.new
    rdoc.document options

    html = File.read(File.join(dir, 'test.html'))
    json = File.read(File.join(dir, 'test.json'))

    [html, json]
  end

  def check_generator(&block)
    html, json = run_generator(source_file, 'test title', &block)

    validator = Html5Validator::Validator.new
    validator.validate_text(html)

    flunk validator.errors.pretty_inspect unless validator.valid?

    JSON.parse json
  end

  def test_defaults
    check_generator
  end

  def test_prefix
    check_generator do |options|
      options.sf_prefix = '/test_prefix'
    end
  end

  def test_template
    check_generator do |options|
      options.sf_template = TemplateLoader.template_path(Settings::DEFAULT_TEMPLATE)
    end
  end

  def test_themes
    check_generator do |options|
      options.sf_themes = [ThemeLoader.theme_path(Settings::DEFAULT_THEME)]
    end
    check_generator do |options|
      options.sf_themes = [Theme1.new.theme_path]
    end
    check_generator do |options|
      options.sf_themes = [Theme2.new.theme_path]
    end
    check_generator do |options|
      options.sf_themes = [Theme1.new.theme_path, Theme2.new.theme_path]
    end
  end

  def test_filters
    check_generator do |options|
      options.sf_filter_classes = '.*'
      options.sf_filter_members = '.*'
    end
    check_generator do |options|
      options.sf_filter_classes = 'nevermatch'
      options.sf_filter_members = 'nevermatch'
    end
  end
end
