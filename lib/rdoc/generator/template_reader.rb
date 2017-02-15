class TemplateReader
  DEFAULT_TEMPLATE = 'onepage'.freeze

  def self.templates_dir(data_dir)
    File.join data_dir, 'templates'
  end

  def self.templates_list(data_dir)
    Dir[File.join(self.templates_dir(data_dir), '*.slim')].sort.map do |path|
      File.basename path, '.slim'
    end
  end

  def self.template_path(name)
    if name.include? '/'
      File.absolute_path name
    else
      name
    end
  end

  def initialize(options)
    @options = options
  end

  def read(templates_dir)
    if @options.rsp_template.include? '/'
      @options.rsp_template
    else
      File.join templates_dir, "#{@options.rsp_template}.slim"
    end
  end
end
