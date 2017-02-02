require 'rdoc/rdoc'
require 'fileutils'
require 'yaml'
require 'sass'
require 'slim'
require 'recursive-open-struct'

require_relative 'doc_reader'

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

  DEFAULT_FILENAME = 'index.html'.freeze
  DEFAULT_TEMPLATE = 'onepage'.freeze
  DEFAULT_THEME    = 'light'.freeze

  def self.setup_options(rdoc_options)
    rdoc_options.rsp_filename = DEFAULT_FILENAME
    rdoc_options.rsp_template = DEFAULT_TEMPLATE
    rdoc_options.rsp_themes   = []

    opt = rdoc_options.option_parser
    opt.separator 'RSinglePage generator options:'

    opt.separator nil
    opt.on('--rsp-filename=FILE', String,
           'Set output HTML file name.',
           "Defaults to '#{DEFAULT_FILENAME}'.") do |value|
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
           "Set template. Defaults to '#{DEFAULT_TEMPLATE}'.",
           "If name contains slash, it's a path, and",
           "otherwise it's a name of installed template.",
           'Installed templates:',
           *(templates_list.map { |s| " - #{s}" })) do |value|
      rdoc_options.rsp_template = template_path(value)
    end

    opt.separator nil
    opt.on('--rsp-theme=NAME', String,
           "Set theme. Defaults to '#{DEFAULT_THEME}'. Specify",
           'multiple times to merge several themes. Every',
           'next theme overwrites options set by previous',
           "themes. If name contains slash, it's a path,",
           "and otherwise it's a name of installed theme.",
           'Installed themes:',
           *(themes_list.map { |s| " - #{s}" })) do |value|
      rdoc_options.rsp_themes << theme_path(value)
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

    template = get_template
    theme = get_theme

    title = get_title
    classes = doc_reader.classes

    generate_theme_files(theme)

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
      if File.extname(file[:src_path]) == '.sass'
        generate_css_from_sass(file)
      end
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
    file[:url] = get_url(file[:dst_name])
    file[:data] = output_data
  end

  def self.data_dir
    File.join File.dirname(__FILE__), '../../../data/rdoc-generator-singlepage'
  end

  def self.templates_dir
    File.join data_dir, 'templates'
  end

  def self.templates_list
    Dir[File.join(templates_dir, '*.slim')].sort.map do |path|
      File.basename path, '.slim'
    end
  end

  def self.template_path(name)
    if name.include? '/'
      File.absolute_path name
    else
      name
    end
  end

  def get_template
    if @options.rsp_template.include? '/'
      @options.rsp_template
    else
      File.join self.class.templates_dir, "#{@options.rsp_template}.slim"
    end
  end

  def self.themes_dir
    File.join data_dir, 'themes'
  end

  def self.themes_list
    Dir[File.join(themes_dir, '*.yml')].sort.map do |path|
      File.basename path, '.yml'
    end
  end

  def self.theme_path(name)
    if name.include? '/'
      File.absolute_path name
    else
      File.join themes_dir, "#{name}.yml"
    end
  end

  def theme_file_path(theme_path, file_path)
    File.join(File.dirname(theme_path), file_path)
  end

  def get_theme
    theme = {
      head: {
        styles: [],
        fonts: [],
        scripts: [],
        html: []
      },
      body: {}
    }

    theme_list = if @options.rsp_themes.empty?
                   Array[self.class.theme_path DEFAULT_THEME]
                 else
                   @options.rsp_themes
                 end

    theme_list.each do |theme_path|
      add_theme(theme, theme_path)
    end

    theme
  end

  def add_theme(theme, theme_path)
    config = YAML.load_file theme_path

    config.each do |section, content|
      check_one_of(
        message:  'Unexpected section in theme config',
        expected: %w(head body),
        actual:   section
      )

      case section
      when 'head'
        content.each do |key, files|
          check_one_of(
            message:  "Unexpected key in 'head'",
            expected: %w(styles fonts scripts html),
            actual:   key
          )
          section = key.to_sym
          files.each do |file_info|
            path = theme_file_path(theme_path, file_info['file'])
            case section
            when :styles, :scripts, :fonts
              name = File.basename(path)
              file = {
                src_path: path,
                dst_name: name,
                url:      get_url(name)
              }
            when :html
              file = {
                data: File.read(path)
              }
            end
            file[:family] = file_info['family'] if section == :fonts
            theme[:head][section] << file
          end
        end

      when 'body'
        content.each do |key, path|
          check_one_of(
            message:  "Unexpected key in 'body'",
            expected: %w(header footer),
            actual:   key
          )
          theme[:body][key.to_sym] = File.read(theme_file_path(theme_path, path))
        end
      end
    end
  rescue => error
    raise "Can't load theme - #{theme_path}\n#{error}"
  end

  def get_url(name)
    prefix = @options.rsp_prefix || ''
    prefix += '/' if !prefix.empty? && !prefix.end_with?('/')
    prefix + name
  end

  def get_title
    @options.title
  end

  def check_one_of(message: '', expected: [], actual: '')
    unless expected.include?(actual)
      raise %(#{message}: ) +
            %(got '#{actual}', ) +
            %(expected one of: #{expected.map { |e| "'#{e}'" }.join(', ')})
    end
  end
end
