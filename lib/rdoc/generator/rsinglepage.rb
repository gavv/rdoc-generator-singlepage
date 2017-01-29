require 'rdoc/rdoc'
require 'builder'
require 'yaml'
require 'fileutils'

class RDoc::Options
  attr_accessor :rsp_theme
  attr_accessor :rsp_filename
  attr_accessor :rsp_filter_classes
  attr_accessor :rsp_filter_members
  attr_accessor :rsp_group_members
end

class RDoc::Generator::RSinglePage
  RDoc::RDoc.add_generator(self)

  def self.setup_options(rdoc_options)
    rdoc_options.rsp_theme    = 'default'
    rdoc_options.rsp_filename = 'index.html'

    opt = rdoc_options.option_parser
    opt.separator 'RSinglePage generator options:'

    opt.separator nil
    opt.on('--rsp-theme=NAME', String,
           "Set theme. Defaults to '#{rdoc_options.rsp_theme}'.",
           'Available themes:',
           *(themes_list.map { |s| " - #{s}" })) do |value|
      rdoc_options.rsp_theme = value
    end

    opt.separator nil
    opt.on('--rsp-filename=FILE', String,
           'Set output HTML file name.',
           "Defaults to '#{rdoc_options.rsp_filename}'.") do |value|
      rdoc_options.rsp_filename = value
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
    File.open(@options.rsp_filename, 'w') do |file|
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
    to_html builder
  end

  def to_html(builder)
    "<!DOCTYPE html>\n#{builder}"
  end

  def new_builder(theme, title, classes)
    doc = Builder::XmlMarkup.new(indent: 2)

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
          doc.text! title
        end

        doc.aside do
          classes.each do |klass|
            if klass[:groups].empty?
              doc.div(class: :tocClassBlock) do
                doc.a(class: :tocClass, href: '#' + klass[:name]) do
                  doc.text! klass[:name]
                end
              end
            else
              doc.details(class: :tocClassBlock) do
                doc.summary do
                  doc.a(class: :tocClass, href: '#' + klass[:name]) do
                    doc.text! klass[:name]
                  end
                end
                doc.div(class: :tocGroupBlock) do
                  klass[:groups].each do |group|
                    doc.a(class: :tocGroup,
                          href: '#' + klass[:name] + '::' + group[:name]) do
                      doc.text! group[:name]
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
                doc.text! klass[:name]
              end

              klass[:groups].each do |group|
                doc.section(id: klass[:name] + '::' + group[:name]) do
                  doc.header do
                    doc.text! group[:name]
                  end

                  group[:members].each do |member|
                    doc.div(class: :memberBlock) do
                      if member[:name]
                        doc.span(class: :memberName) do
                          doc.text! member[:name]
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
      end
    end

    doc
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
    theme_name = @options.rsp_theme

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
      next unless group = get_member_group(klass, method)
      unless groups.include? group
        groups[group] = {
          name:    group,
          members: []
        }
      end
      groups[group][:members] << method
    end

    attr = {
      'Instance Attributes' => klass.instance_attributes,
      'Class Attributes' => klass.class_attributes
    }

    attr.each do |k, v|
      groups[k] = {
        name: k,
        members: []
      }
      v.each do |a|
        groups[k][:members] << {
          name: "#{a.name} #{a.rw}",
          comment: get_comment(a)
        }
      end
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

  def get_member_group(klass, member)
    if @options.rsp_group_members
      get_member_group_from_match(member[:name])
    elsif contain_member(klass.instance_method_list, member[:name])
      'Class Methods'
    elsif contain_member(klass.class_method_list, member[:name])
      'Instance Methods'
    end
  end

  def contain_member(methods, member_name)
    methods.select { |m| m.name == member_name }.size == 1
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
