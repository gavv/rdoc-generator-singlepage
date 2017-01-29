require 'rdoc/rdoc'
require 'builder'
require 'yaml'
require 'fileutils'

class RDoc::Options
  attr_accessor :rsp_filename
  attr_accessor :rsp_prefix
  attr_accessor :rsp_themes
  attr_accessor :rsp_filter_classes
  attr_accessor :rsp_filter_members
  attr_accessor :rsp_group_members
end

class RDoc::Generator::RSinglePage
  RDoc::RDoc.add_generator(self)

  DEFAULT_FILENAME = 'index.html'.freeze
  DEFAULT_THEME    = 'default'.freeze

  def self.setup_options(rdoc_options)
    rdoc_options.rsp_filename = DEFAULT_FILENAME
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
    opt.on('--rsp-theme=NAME', String,
           "Set theme. Defaults to '#{DEFAULT_THEME}'. Specify",
           'multiple times to merge several themes. Every',
           'next theme overwrites options set by previous',
           "themes. If name contains slash, it's a path,",
           "and otherwise it's a name of installed theme.",
           'Installed themes:',
           *(themes_list.map { |s| " - #{s}" })) do |value|
      # Expand path while parsing options, because later RDoc will
      # chdir into the output directory and we'll not be able to
      # resolve relative paths correctly.
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

    opt.separator nil
    opt.on('--rsp-group-members=REGEX', String,
           'Group members by regex instead of default',
           'grouping. First regex capture group is used',
           'as a group name.') do |value|
      rdoc_options.rsp_group_members = Regexp.new(value)
    end
  end

  def initialize(store, options)
    @store = store
    @options = options
  end

  def generate
    theme = load_theme

    title = get_title
    classes = get_classes

    builder = new_builder(theme, title, classes)
    html = generate_html(builder)

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
    theme[:head].each do |_type, file|
      FileUtils.copy_file(file[:path], file[:name])
    end
  end

  def install_html_file(html)
    File.open(@options.rsp_filename, 'w') do |file|
      file.write(html)
    end
  end

  def generate_html(builder)
    "<!DOCTYPE html>\n#{builder}"
  end

  def new_builder(theme, title, classes)
    doc = Builder::XmlMarkup.new(indent: 2)

    doc.html do
      doc.head do
        doc.meta(charset: 'UTF-8')

        theme[:head].each do |type, file|
          case type
          when :style, :font
            doc.link(rel: :stylesheet, href: file[:url])
          when :script
            doc.script(src: file[:url]) do
            end
          when :html
            doc << data
          end
        end
      end

      doc.body do
        doc << theme[:body][:header] if theme[:body][:header]

        doc.header do
          doc.text! title
        end

        doc.aside do
          classes.each do |klass|
            if klass[:groups].empty?
              doc.div(class: :tocClassBlock) do
                doc.a(class: :tocClass, href: '#' + klass[:id]) do
                  doc.text! klass[:title]
                end
              end
            else
              doc.details(class: :tocClassBlock) do
                doc.summary do
                  doc.a(class: :tocClass, href: '#' + klass[:id]) do
                    doc.text! klass[:title]
                  end
                end
                doc.div(class: :tocGroupBlock) do
                  klass[:groups].each do |group|
                    doc.a(class: :tocGroup,
                          href: '#' + group[:id]) do
                      doc.text! group[:title]
                    end
                  end
                end
              end
            end
          end
        end

        doc.main do
          classes.each do |klass|
            doc.article(id: klass[:id]) do
              doc.header do
                doc.text! klass[:title]
              end

              klass[:groups].each do |group|
                doc.section(id: group[:id]) do
                  doc.header do
                    doc.text! group[:title]
                  end

                  group[:members].each do |member|
                    doc.div(class: :memberBlock) do
                      if member[:title]
                        doc.span(class: :memberName) do
                          doc.text! member[:title]
                        end
                      end

                      if member[:comment]
                        doc.span(class: :memberComment) do
                          doc << member[:comment]
                        end
                      end

                      if member[:code]
                        doc.details(class: :memberCode) do
                          doc.summary do
                            doc.text! 'Show code'
                          end
                          doc.pre do
                            doc << member[:code]
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end

        doc << theme[:body][:footer] if theme[:body][:footer]
      end
    end

    doc
  end

  def self.themes_dir
    File.join File.dirname(__FILE__), '../../../data/rdoc-generator-singlepage/themes'
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

  def load_theme
    theme = {
      head: {},
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

    config.each do |section, files|
      check_one_of(
        message:  'Unexpected section in theme config',
        expected: %w(head body),
        actual:   section
      )

      case section
      when 'head'
        files.each do |type, path|
          check_one_of(
            message:  "Unexpected file type in 'head' section of theme config",
            expected: %w(style font script html),
            actual:   type
          )
          path = theme_file_path(theme_path, path)
          name = File.basename(path)
          theme[:head][type.to_sym] = {
            name: name,
            url:  get_url(name),
            path: path
          }
        end

      when 'body'
        files.each do |type, path|
          check_one_of(
            message:  "Unexpected file type in 'body' section of theme config",
            expected: %w(header footer),
            actual:   type
          )
          theme[:body][type.to_sym] = File.read(theme_file_path(theme_path, path))
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

  def get_classes
    classes = @store.all_classes_and_modules

    classes = classes.select do |klass|
      !skip_class? klass.full_name
    end

    classes.sort_by!(&:full_name)

    classes.map do |klass|
      {
        id:    klass.full_name,
        title: klass.full_name,
        comment: get_comment(klass),
        groups:  get_groups(klass)
      }
    end
  end

  def get_groups(klass)
    members = get_members(klass)
    groups = {}

    members.each do |member|
      group = get_member_group(member)
      next unless group

      unless groups.include? group
        groups[group] = {
          title: group,
          id: klass.full_name.strip + '::' + group.strip,
          members: []
        }
      end

      groups[group][:members] << member
    end

    groups.values
  end

  def get_members(klass)
    members = []

    method_members = get_raw_members klass.method_list do |member|
      member[:kind] = :method
    end

    attr_members = get_raw_members klass.attributes do |member|
      member[:kind] = :attribute
    end

    members.push(*method_members)
    members.push(*attr_members)

    members
  end

  def get_raw_members(member_list)
    members = []

    member_list.each do |m|
      next if skip_member? m.name

      member = {}
      member[:id] = m.name if m.name
      member[:title] = m.name if m.name
      member[:comment] = get_comment(m)
      member[:code] = m.markup_code if m.markup_code && m.markup_code != ''
      member[:level] = m.type.to_sym if m.type
      member[:visibility] = m.visibility.to_sym if m.visibility

      yield member

      members << member
    end

    members
  end

  def get_comment(object)
    if object.comment.respond_to? :text
      object.description.strip
    else
      object.comment
    end
  end

  def get_member_group(member)
    if @options.rsp_group_members
      get_member_group_from_match(member[:title])
    else
      get_member_group_with_default_grouping(member)
    end
  end

  def get_member_group_with_default_grouping(member)
    case member[:kind]
    when :method
      case member[:level]
      when :instance
        'Instance Methods'
      when :class
        'Class Methods'
      end
    when :attribute
      case member[:level]
      when :instance
        'Instance Attributes'
      when :class
        'Class Attributes'
      end
    end
  end

  def get_member_group_from_match(member_name)
    if m = @options.rsp_group_members.match(member_name)
      if m.length != 2
        raise "Invalid group-members regex: /#{@options.rsp_group_members}/\n" \
              'Expected exactly one capture group.'
      end
      m[1]
    end
  end

  def skip_class?(class_name)
    if @options.rsp_filter_classes
      @options.rsp_filter_classes.match(class_name).nil?
    else
      false
    end
  end

  def skip_member?(member_name)
    if @options.rsp_filter_members
      @options.rsp_filter_members.match(member_name).nil?
    else
      false
    end
  end

  def check_one_of(message: '', expected: [], actual: '')
    unless expected.include?(actual)
      raise %(#{message}: ) +
            %(got '#{actual}', ) +
            %(expected one of: #{expected.map { |e| "'#{e}'" }.join(', ')})
    end
  end
end
