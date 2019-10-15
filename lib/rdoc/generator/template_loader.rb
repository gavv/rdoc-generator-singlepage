# frozen_string_literal: true

require 'slim'
require 'recursive-open-struct'

require_relative 'settings'

# TemplateLoader reads a template from `.slim' file and builds a Template object
# that may render HTML given a hash with documentation and theme.
class TemplateLoader
  def self.templates_list
    Settings.list_file_names 'templates', '.slim'
  end

  def self.template_path(name)
    Settings.find_file 'templates', '.slim', name
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
