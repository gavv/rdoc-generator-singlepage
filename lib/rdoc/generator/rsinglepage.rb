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
    theme[:head].values.each do |files|
      files.each do |file|
        if file[:src_path] && file[:dst_name]
          FileUtils.copy_file(file[:src_path], file[:dst_name])
        end
      end
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

        unless theme[:head][:fonts].empty?
          doc.style do
            theme[:head][:fonts].each do |file|
              doc << "@font-face {\n"
              doc << "  font-family: '#{file[:family]}';\n"
              doc << "  src: url('#{file[:url]}');\n"
              doc << "}\n"
            end
          end
        end

        theme[:head][:styles].each do |file|
          doc.link(rel: :stylesheet, href: file[:url])
        end

        theme[:head][:scripts].each do |file|
          doc.script(src: file[:url]) do
          end
        end

        theme[:head][:html].each do |file|
          doc << file[:data]
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
              doc.div(class: css_classes(:tocClassBlock, klass)) do
                doc.a(class: :tocClass, href: '#' + klass[:id]) do
                  doc.text! klass[:title]
                end
              end
            else
              doc.details(class: css_classes(:tocClassBlock, klass)) do
                doc.summary do
                  doc.a(class: :tocClass, href: '#' + klass[:id]) do
                    doc.text! klass[:title]
                  end
                end
                doc.div(class: :tocGroupBlock) do
                  klass[:groups].each do |group|
                    doc.a(class: css_classes(:tocGroup, group),
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
            doc.article(id: klass[:id], class: css_classes(:classBlock, klass)) do
              doc.header do
                doc.text! klass[:title]
              end

              klass[:groups].each do |group|
                doc.section(id: group[:id], class: :groupBlock) do
                  doc.header do
                    doc.text! group[:title]
                  end

                  group[:members].each do |member|
                    doc.div(class: css_classes(:memberBlock, member)) do
                      if member[:id]
                        doc.span(class: :memberName) do
                          doc.text! member[:id]
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
                            doc.text! 'Source code'
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

  def css_classes(main_class, object)
    classes = [main_class]
    classes += css_indicator_classes(object)
    classes.join(' ')
  end

  def css_indicator_classes(object)
    classes = []

    case object[:kind]
    when :method
      classes << :rbKindMethod
    when :constant
      classes << :rbKindConstant
    when :attribute
      classes << :rbKindAttribute
    when :included
      classes << :rbKindIncluded
    when :extended
      classes << :rbKindExtended
    when :class
      classes << :rbKindClass
    when :module
      classes << :rbKindModule
    end

    case object[:level]
    when :instance
      classes << :rbLevelInstance
    when :class
      classes << :rbLevelClass
    end

    case object[:visibility]
    when :public
      classes << :rbVisibilityPublic
    when :private
      classes << :rbVisibilityPrivate
    when :protected
      classes << :rbVisibilityProtected
    end

    classes
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
      merge_theme(theme, theme_path)
    end

    theme
  end

  def merge_theme(theme, theme_path)
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
        kind: get_class_kind(@store, klass.full_name),
        comment: get_comment(klass),
        groups:  get_groups(klass)
      }
    end
  end

  def get_class_kind(store, class_name)
    if store.all_modules.select { |m| m.full_name == class_name }.size == 1
      :module
    else
      :class
    end
  end

  def get_groups(klass)
    members = get_members(klass)
    groups = {}

    members.each do |member|
      group = get_member_group(member)
      next unless group

      group_id = klass.full_name.strip + '::' + group[:title].strip

      unless groups.include? group_id
        groups[group_id] = group.merge(
          id: group_id,
          members: []
        )
      end

      groups[group_id][:members] << member
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

    const_members = get_raw_members klass.constants do |member|
      member[:kind] = :constant
    end

    extends_members = get_raw_members klass.extends do |member|
      member[:kind] = :extended
    end

    include_members = get_raw_members klass.includes do |member|
      member[:kind] = :included
    end

    members.push(*method_members)
    members.push(*attr_members)
    members.push(*const_members)
    members.push(*extends_members)
    members.push(*include_members)

    members
  end

  def get_raw_members(member_list)
    members = []

    member_list.each do |m|
      next if skip_member? m.name

      member = {}
      member[:id] = if m.respond_to? :arglists
                      if m.arglists
                        m.arglists
                      else
                        m.name
                      end
                    else
                      m.name
                    end

      member[:title] = m.name if m.name
      member[:comment] = get_comment(m)

      if m.respond_to? :markup_code
        member[:code] = m.markup_code if m.markup_code && m.markup_code != ''
      end

      if m.respond_to? :type
        member[:level] = m.type.to_sym if m.type
      end

      if m.respond_to? :visibility
        member[:visibility] = m.visibility.to_sym if m.visibility
      end

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
        {
          title: 'Instance Methods',
          kind:  :method,
          level: :instance
        }
      when :class
        {
          title: 'Class Methods',
          kind:  :method,
          level: :class
        }
      end
    when :attribute
      case member[:level]
      when :instance
        {
          title: 'Instance Attributes',
          kind:  :attribute,
          level: :instance
        }
      when :class
        {
          title: 'Class Attributes',
          kind:  :attribute,
          level: :class
        }
      end
    when :constant
      {
        title: 'Constants',
        kind:  :constant
      }
    when :extended
      {
        title: 'Extend Modules',
        kind:  :extended
      }
    when :included
      {
        title: 'Include Modules',
        kind:  :included
      }
    end
  end

  def get_member_group_from_match(member_name)
    if m = @options.rsp_group_members.match(member_name)
      if m.length != 2
        raise "Invalid group-members regex: /#{@options.rsp_group_members}/\n" \
              'Expected exactly one capture group.'
      end
      {
        title: m[1]
      }
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
