require 'slim'
require 'recursive-open-struct'

require_relative 'settings'

# TemplateLoader reads a template from `.slim' file and builds a Template object
# that may render HTML given a hash with documentation and theme.
class TemplateLoader
  def self.templates_dir
    File.join Settings.data_dir, 'templates'
  end

  def self.templates_list
    pattern = File.join templates_dir, '*.slim'

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

# Template allows to render HTML from a given hash with documentation and theme.
class Template
  def initialize(path)
    @path = path
  end

  def render(data)
    opts = {
      pretty: true
    }

    vars = RecursiveOpenStruct.new(data, recurse_over_arrays: true)

    template = Slim::Template.new(@path, opts)
    template.render(vars)
  end
end
