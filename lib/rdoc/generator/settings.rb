require 'pathname'

# Predefined configuration.
module Settings
  DEFAULT_HTMLFILE = 'index.html'.freeze
  DEFAULT_TEMPLATE = 'onepage'.freeze
  DEFAULT_THEME    = 'light'.freeze

  def self.data_dir
    Pathname.new(
      File.join(
        File.dirname(__FILE__),
        '../../../data/rdoc-generator-solarfish'
      )
    ).cleanpath.to_s
  end
end
