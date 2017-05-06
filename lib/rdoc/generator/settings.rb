require 'pathname'

# Predefined configuration.
module Settings
  DEFAULT_HTMLFILE = 'index.html'.freeze
  DEFAULT_TEMPLATE = 'onepage'.freeze
  DEFAULT_THEME    = 'light'.freeze

  def self.data_dir
    pn = Pathname.new(
      File.join(File.dirname(__FILE__), '../../../data/rdoc-generator-solarfish')
    )
    pn = pn.cleanpath
    pn.to_s
  end
end
