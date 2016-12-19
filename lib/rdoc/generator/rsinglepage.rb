require 'rdoc/rdoc'
require 'nokogiri'
require 'fileutils'

class RDoc::Generator::RSinglePage

  RDoc::RDoc.add_generator(self)

  def initialize(store, options)
    @store = store
    @options = options
  end

  def generate
    File.open(get_output_file, 'w') do |file|
      file.write(get_html)
    end
  end

  def class_dir
    nil
  end

  def file_dir
    nil
  end

  private

  def get_output_file
    # TODO: move to config
    'doc.html'
  end

  def get_data_dir
    File.join File.dirname(__FILE__), '../../../data/rdoc-generator-singlepage'
  end

  def get_html
    builder = get_builder get_classes
    builder.to_html
  end

  def get_builder(classes)
    Nokogiri::HTML::Builder.new(:encoding => 'UTF-8') do |doc|
      doc.html do
        doc.head do
          doc.style do
            doc << get_css
          end
        end

        doc.body do
          doc.h1 do
            doc.text get_title
          end

          doc.div.top do
            doc.div.tocbox do
              classes.each do |klass|
                doc.div.tocclassbox do
                  doc.div.tocclassheader do
                    doc.a(href: '#' + klass[:name]).classref do
                      doc.text klass[:name]
                    end
                  end

                  klass[:groups].each do |group|
                    doc.div.tocgroup do
                      doc.a(href: '#' + klass[:name] + '::' + group[:name]).groupref do
                        doc.text group[:name]
                      end
                    end
                  end
                end
              end
            end

            doc.div.mainbox do
              classes.each do |klass|
                doc.div.classbox(id: klass[:name]) do
                  doc.div.classheader do
                    doc.span.classname do
                      doc.text klass[:name]
                    end
                  end

                  klass[:groups].each do |group|
                    doc.div.groupbox(id: klass[:name] + '::' + group[:name]) do
                      doc.div.groupheader do
                        doc.span.groupname do
                          doc.text group[:name]
                        end
                      end

                      group[:methods].each do |method|
                        doc.div.methodbox do
                          doc.span.methodname do
                            doc.text method[:name]
                          end
                          doc.span.comment do
                            doc << method[:comment]
                          end
                          doc.div.code do
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
  end

  def get_css
    # TODO: move to theme, get theme from config
    File.open(File.join get_data_dir, 'default.css') do |file|
      file.read
    end
  end

  def get_title
    @options.title
  end

  def get_classes
    classes = @store.all_classes_and_modules

    classes = classes.select do |klass|
      !skip_class? klass.full_name
    end

    classes.sort_by! do |klass|
      klass.full_name
    end

    classes.map do |klass|
      {
        name:    klass.full_name,
        comment: get_comment(klass),
        groups:  get_groups(klass),
      }
    end
  end

  def get_groups(klass)
    methods = get_methods(klass)
    groups = {}

    methods.each do |method|
      if group = get_group_name(method[:name])
        if !groups.include? group
          groups[group] = {
            name:    group,
            methods: []
          }
        end
        groups[group][:methods] << method
      end
    end

    groups.values
  end

  def get_methods(klass)
    methods = klass.method_list

    methods = methods.select do |method|
      !skip_method? method.name
    end

    methods.map do |method|
      {
        name:    method.name,
        comment: get_comment(method),
        code:    method.markup_code,
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

  def get_group_name(method_name)
    # TODO: move to config
    m = /^test_([^_]+)/.match(method_name)
    m[1] if m
  end

  def skip_class?(class_name)
    # TODO: move to config
    !class_name.start_with? 'Test'
  end

  def skip_method?(method_name)
    # TODO: move to config
    !method_name.start_with? 'test_'
  end
end
