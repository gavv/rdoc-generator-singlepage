module DataDir
  DEFAULT_FILENAME = 'index.html'.freeze

  def self.path
    File.join File.dirname(__FILE__), '../../../data/rdoc-generator-singlepage'
  end
end
