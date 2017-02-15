require 'rdoc/rdoc'
require 'fileutils'
require 'yaml'
require 'sass'
require 'slim'
require 'recursive-open-struct'

require_relative 'doc_reader'
require_relative 'data_dir'
require_relative 'template_reader'
require_relative 'theme_reader'

class RDoc::Options
  attr_accessor :rsp_filename
  attr_accessor :rsp_prefix
  attr_accessor :rsp_template
  attr_accessor :rsp_themes
  attr_accessor :rsp_filter_classes
  attr_accessor :rsp_filter_members
end

class RDoc::Generator::RSinglePage
  RDoc::RDoc.add_generator(self)

  def self.setup_options(rdoc_options)
    rdoc_options.rsp_filename = DataDir::DEFAULT_FILENAME
    rdoc_options.rsp_template = TemplateReader::DEFAULT_TEMPLATE
    rdoc_options.rsp_themes   = []

    opt = rdoc_options.option_parser
    opt.separator 'RSinglePage generator options:'

    opt.separator nil
    opt.on('--rsp-filename=FILE', String,
           'Set output HTML file name.',
           "Defaults to '#{DataDir::DEFAULT_FILENAME}'.") do |value|
      rdoc_options.rsp_filename = value
    end

    opt.separator nil
    opt.on('--rsp-prefix=PREFIX', String,
           'Set URL prefix for links to stylesheets and',
           'scripts in generated HTML. Empty by default.') do |value|
      rdoc_options.rsp_prefix = value
    end

    opt.separator nil
    opt.on('--rsp-template=NAME', String,
           "Set template. Defaults to '#{TemplateReader::DEFAULT_TEMPLATE}'.",
           "If name contains slash, it's a path, and",
           "otherwise it's a name of installed template.",
           'Installed templates:',
           *(TemplateReader.templates_list(DataDir.path).
             map { |s| " - #{s}" })) do |value|
      rdoc_options.rsp_template = TemplateReader.template_path(value)
    end

    opt.separator nil
    opt.on('--rsp-theme=NAME', String,
           "Set theme. Defaults to '#{ThemeReader::DEFAULT_THEME}'. Specify",
           'multiple times to merge several themes. Every',
           'next theme overwrites options set by previous',
           "themes. If name contains slash, it's a path,",
           "and otherwise it's a name of installed theme.",
           'Installed themes:',
           *(ThemeReader.themes_list(DataDir.path).
             map { |s| " - #{s}" })) do |value|
      rdoc_options.rsp_themes << ThemeReader.theme_path(value)
    end

    opt.separator nil
    opt.on('--rsp-filter-classes=REGEX', String,
           'Include only classes and modules that',
           'match regex.') do |value|
      rdoc_options.rsp_filter_classes = Regexpn.new(value)
    end

    opt.separator nil
    opt.on('--rsp-filter-members=REGEX', String,
           'Include only members that match regex.') do |value|
      rdoc_options.rsp_filter_members = Regexp.new(value)
    end
  end

  def initialize(store, options)
    @store = store
    @options = options
  end

  def generate
    doc_reader = DocReader.new(@store, @options)
    classes = doc_reader.classes

    theme_reader = ThemeReader.new(@options)
    theme_dir = ThemeReader.theme_path(ThemeReader::DEFAULT_THEME, DataDir.path)
    theme = theme_reader.read(theme_dir)
    generate_theme_files(theme)

    template_reader = TemplateReader.new(@options)
    templates_dir = TemplateReader.templates_dir(DataDir.path)
    template = template_reader.read(templates_dir)

    title = get_title
    html = generate_html(template, theme, title, classes)

    install_theme_files(theme)
    install_html_file(html)
  end

  def class_dir
    nil
  end

  def file_dir
    nil
  end

  private

  def install_theme_files(theme)
    theme[:head].values.each do |files|
      files.each do |file|
        if file[:dst_name]
          if file[:src_path]
            FileUtils.copy_file(file[:src_path], file[:dst_name])
          elsif file[:data]
            File.write(file[:dst_name], file[:data])
          end
        end
      end
    end
  end

  def install_html_file(html)
    File.open(@options.rsp_filename, 'w') do |file|
      file.write(html)
    end
  end

  def generate_html(template, theme, title, classes)
    options = {
      pretty: true
    }

    vars = {
      theme:   theme,
      title:   title,
      classes: classes
    }

    scope = RecursiveOpenStruct.new(vars, recurse_over_arrays: true)

    template = Slim::Template.new(template, options)
    template.render(scope)
  end

  def generate_theme_files(theme)
    theme[:head][:styles].each do |file|
      generate_css_from_sass(file) if File.extname(file[:src_path]) == '.sass'
    end
  end

  def generate_css_from_sass(file)
    options = {
      cache:  false,
      syntax: :sass,
      style:  :default
    }

    input_data = File.read(file[:src_path])
    renderer = Sass::Engine.new(input_data, options)
    output_data = renderer.render

    file.delete(:src_path)
    file[:dst_name] = File.basename(file[:dst_name], '.*') + '.css'
    file[:url] = ThemeReader.build_url(file[:dst_name], @options.rsp_prefix)
    file[:data] = output_data
  end

  def get_title
    @options.title
  end
end
