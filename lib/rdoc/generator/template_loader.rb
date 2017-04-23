require 'slim'
require 'recursive-open-struct'

require_relative 'settings'

class TemplateLoader
  def self.templates_dir
    File.join Settings::data_dir, 'templates'
  end

  def self.templates_list
    pattern = File.join self.templates_dir, '*.slim'

    Dir[pattern].sort.map do |path|
      File.basename path, '.slim'
    end
  end

  def self.template_path(name)
    if name.include? '/'
      File.absolute_path name
    else
      File.join templates_dir, "#{name}.slim"
    end
  end

  def initialize(options)
    @options = options
  end

  def load
    Template.new @options.sf_template
  end
end

class Template
  def initialize(path)
    @path = path
  end

  def render(vars)
    opts = {
      pretty: true
    }

    scope = RecursiveOpenStruct.new(vars, recurse_over_arrays: true)

    template = Slim::Template.new(@path, opts)
    template.render(scope)
  end
end
