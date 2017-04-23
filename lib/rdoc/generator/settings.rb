module Settings
  DEFAULT_HTMLFILE = 'index.html'.freeze
  DEFAULT_TEMPLATE = 'onepage'.freeze
  DEFAULT_THEME    = 'light'.freeze

  def self.data_dir
    File.join File.dirname(__FILE__), '../../../data/rdoc-generator-solarfish'
  end
end
