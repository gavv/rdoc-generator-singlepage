module Settings
  DEFAULT_FILENAME = 'index.html'.freeze
  DEFAULT_TEMPLATE = 'onepage'.freeze
  DEFAULT_THEME    = 'light'.freeze

  def self.data_dir
    File.join File.dirname(__FILE__), '../../../data/rdoc-generator-singlepage'
  end
end
