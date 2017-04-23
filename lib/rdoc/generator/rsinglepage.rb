require 'rdoc/rdoc'

require_relative 'settings'
require_relative 'doc_loader'
require_relative 'template_loader'
require_relative 'theme_loader'
require_relative 'html_builder'

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
    rdoc_options.rsp_filename = Settings::DEFAULT_FILENAME
    rdoc_options.rsp_template = Settings::DEFAULT_TEMPLATE
    rdoc_options.rsp_themes   = nil

    opt = rdoc_options.option_parser
    opt.separator 'RSinglePage generator options:'

    opt.separator nil
    opt.on('--rsp-filename=FILE', String,
           'Set output HTML file name.',
           "Defaults to '#{Settings::DEFAULT_FILENAME}'.") do |value|
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
           "Set template. Defaults to '#{Settings::DEFAULT_TEMPLATE}'.",
           "If name contains slash, it's a path, and",
           "otherwise it's a name of installed template.",
           'Installed templates:',
           *(TemplateLoader::templates_list().
             map { |s| " - #{s}" })) do |value|
      rdoc_options.rsp_template = TemplateLoader.template_path(value)
    end

    opt.separator nil
    opt.on('--rsp-theme=NAME', String,
           "Set theme. Defaults to '#{Settings::DEFAULT_THEME}'. Specify",
           'multiple times to merge several themes. Every',
           'next theme overwrites options set by previous',
           "themes. If name contains slash, it's a path,",
           "and otherwise it's a name of installed theme.",
           'Installed themes:',
           *(ThemeLoader::themes_list().
              map { |s| " - #{s}" })) do |value|
      rdoc_options.rsp_themes ||= []
      rdoc_options.rsp_themes << ThemeLoader.theme_path(value)
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

  def class_dir
    nil
  end

  def file_dir
    nil
  end

  def generate
    theme_paths = @rsp_themes
    theme_paths ||= [ThemeLoader.theme_path(Settings::DEFAULT_THEME)]

    template_path = @rsp_template
    template_path ||= TemplateLoader.template_path(Settings::DEFAULT_TEMPLATE)

    doc_loader = DocLoader.new(@options, @store)
    classes = doc_loader.load

    theme_loader = ThemeLoader.new(@options)
    theme = theme_loader.load(theme_paths)

    template_loader = TemplateLoader.new
    template = template_loader.load(template_path)

    builder = HTMLBuilder.new(@options)
    builder.build(classes, theme, template)
  end
end
