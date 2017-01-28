require 'rdoc/rdoc'
require 'nokogiri'
require 'yaml'
require 'fileutils'

class RDoc::Options
  attr_accessor :output_file
  attr_accessor :theme_name
  attr_accessor :filter_classes
  attr_accessor :filter_members
  attr_accessor :group_members
end

class RDoc::Generator::RSinglePage
  RDoc::RDoc.add_generator(self)

  def self.setup_options(rdoc_options)
    rdoc_options.output_file = 'index.html'
    rdoc_options.theme_name = 'default'

    opt = rdoc_options.option_parser
    opt.separator 'rsinglepage generator options:'

    opt.separator nil
    opt.on('--theme=NAME', String,
           'Set theme.',
           "Defaults to '#{rdoc_options.theme_name}'.",
           'Available themes:',
           *(themes_list.map { |s| " - #{s}" })) do |value|
      rdoc_options.theme_name = value
    end

    opt.separator nil
    opt.on('--output-file=FILE', '--opf', String,
           'Set output file name.',
           "Defaults to '#{rdoc_options.output_file}'.") do |value|
      rdoc_options.output_file = value
    end

    opt.separator nil
    opt.on('--filter-classes=REGEX', '--fc', String,
           'Include only classes and modules that',
           'match regex.') do |value|
      rdoc_options.filter_classes = Regexp.new(value)
    end

    opt.separator nil
    opt.on('--filter-members=REGEX', '--fm', String,
           'Include only members that match regex.') do |value|
      rdoc_options.filter_members = Regexp.new(value)
    end

    opt.separator nil
    opt.on('--group-members=REGEX', '--gm', String,
           'Group members by regex instead of default',
           'grouping. First capture group defines',
           'the group name.') do |value|
      rdoc_options.group_members = Regexp.new(value)
    end
  end

  def initialize(store, options)
    @store = store
    @options = options
  end

  def generate
    File.open(@options.output_file, 'w') do |file|
      file.write(generate_html)
    end
  end

  def class_dir
    nil
  end

  def file_dir
    nil
  end

  private

  def generate_html
    theme = load_theme
    title = get_title
    classes = get_classes
    builder = new_builder(theme, title, classes)
    root = builder.doc.root
    to_html root
  end

  def to_html(root)
    "<!DOCTYPE html>\n#{root.to_xml}"
  end

  def new_builder(theme, title, classes)
    Nokogiri::XML::Builder.new do |doc|
      doc.html do
        doc.head do
          doc.meta(charset: 'UTF-8')

          theme[:include].each do |type, data|
            case type
            when :css
              doc.style do
                doc << data
              end
            when :js
              doc.script do
                doc << data
              end
            end
          end
        end

        doc.body do
          doc.header do
            doc.h1 do
              doc.text title
            end
          end

          doc.aside do
            classes.each do |klass|
              doc.div.tocClassBlock do
                doc.a(href: '#' + klass[:name]).tocClass do
                  doc.text klass[:name]
                end

                if klass[:groups].length() > 0
                  doc.div.tocGroupBlock do
                    klass[:groups].each do |group|
                      doc.a(href: '#' + klass[:name] + '::' + group[:name]).tocGroup do
                        doc.text group[:name]
                      end
                    end
                  end
                end
              end
            end
          end

          doc.main do
            classes.each do |klass|
              doc.article(id: klass[:name]) do
                doc.header do
                  doc.text klass[:name]
                end

                klass[:groups].each do |group|
                  doc.section(id: klass[:name] + '::' + group[:name]) do
                    doc.header do
                      doc.text group[:name]
                    end

                    group[:methods].each do |method|
                      doc.div.methodBlock do
                        doc.span.methodName do
                          doc.text method[:name]
                        end
                        doc.span.methodComment do
                          doc << method[:comment]
                        end
                        doc.details.methodCode do
                          doc.pre do
                            doc << method[:code]
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
      end
    end
  end

  def self.themes_dir
    File.join File.dirname(__FILE__), '../../../data/rdoc-generator-singlepage/themes'
  end

  def self.themes_list
    Dir[File.join(themes_dir, '*')].sort.select do |path|
      File.directory? path
    end.map do |path|
      File.basename path
    end
  end

  def load_theme
    theme_name = @options.theme_name

    theme_dir = File.join(self.class.themes_dir, theme_name)

    theme = {
      include: {}
    }

    config = YAML.load_file(File.join(theme_dir, 'config.yml'))

    if config['include']
      config['include'].each do |type, path|
        check_one_of(
          message:  'Unexpected include file type in theme config',
          expected: %w(css js),
          actual:   type
        )
        File.open(File.join(theme_dir, path)) do |file|
          theme[:include][type.to_sym] = file.read
        end
      end
    end

    theme

  rescue => error
    raise "Can't load '#{theme_name}' theme\n#{error}"
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
        name:    klass.full_name,
        comment: get_comment(klass),
        groups:  get_groups(klass)
      }
    end
  end

  def get_groups(klass)
    methods = get_methods(klass)
    groups = {}

    methods.each do |method|
      next unless group = get_member_group(method)
      unless groups.include? group
        groups[group] = {
          name:    group,
          methods: []
        }
      end
      groups[group][:methods] << method
    end

    groups.values
  end

  def get_methods(klass)
    methods = klass.method_list

    methods = methods.select do |method|
      !skip_member? method.name
    end

    methods.map do |method|
      {
        name:    method.name,
        comment: get_comment(method),
        code:    method.markup_code
      }
    end
  end

  def get_comment(object)
    if object.comment.respond_to? :text
      object.description.strip
    else
      object.comment
    end
  end

  def get_member_group(member)
    if @options.group_members
      get_member_group_from_match(member[:name])
    else
      # TODO: group by member kind: attribute, method, ...
      'default_group'
    end
  end

  def get_member_group_from_match(member_name)
    if m = @options.group_members.match(member_name)
      if m.length != 2
        raise "Invalid group-members regex: /#{@options.group_members}/\n" \
              'Expected exactly one capture group.'
      end
      m[1]
    end
  end

  def skip_class?(class_name)
    if @options.filter_classes
      @options.filter_classes.match(class_name).nil?
    else
      false
    end
  end

  def skip_member?(member_name)
    if @options.filter_members
      @options.filter_members.match(member_name).nil?
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
