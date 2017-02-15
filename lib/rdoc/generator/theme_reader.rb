class ThemeReader
  DEFAULT_THEME    = 'light'.freeze

  def self.themes_dir(data_dir)
    File.join data_dir, 'themes'
  end

  def self.themes_list(data_dir)
    Dir[File.join(themes_dir(data_dir), '*.yml')].sort.map do |path|
      File.basename path, '.yml'
    end
  end

  def self.theme_path(name, data_dir)
    if name.include? '/'
      File.absolute_path name
    else
      File.join self.themes_dir(data_dir), "#{name}.yml"
    end
  end

  def self.build_url(name, prefix)
    url = prefix || ''
    url += '/' if !url.empty? && !url.end_with?('/')
    url + name
  end

  def initialize(options)
    @options = options
  end

  def read(default_theme_path)
    theme = {
      head: {
        styles: [],
        fonts: [],
        scripts: [],
        html: []
      },
      body: {}
    }

    theme_list = if @options.rsp_themes.empty?
                   Array[default_theme_path]
                 else
                   @options.rsp_themes
                 end

    theme_list.each do |theme_path|
      add_theme(theme, theme_path)
    end

    theme
  end

  private

  def add_theme(theme, theme_path)
    config = YAML.load_file theme_path

    config.each do |section, content|
      check_one_of(
        message:  'Unexpected section in theme config',
        expected: %w(head body),
        actual:   section
      )

      case section
      when 'head'
        content.each do |key, files|
          check_one_of(
            message:  "Unexpected key in 'head'",
            expected: %w(styles fonts scripts html),
            actual:   key
          )
          section = key.to_sym
          files.each do |file_info|
            path = theme_file_path(theme_path, file_info['file'])
            case section
            when :styles, :scripts, :fonts
              name = File.basename(path)
              file = {
                src_path: path,
                dst_name: name,
                url:      ThemeReader.build_url(name, @options.rsp_prefix)
              }
            when :html
              file = {
                data: File.read(path)
              }
            end
            file[:family] = file_info['family'] if section == :fonts
            theme[:head][section] << file
          end
        end

      when 'body'
        content.each do |key, path|
          check_one_of(
            message:  "Unexpected key in 'body'",
            expected: %w(header footer),
            actual:   key
          )
          theme[:body][key.to_sym] = File.read(theme_file_path(theme_path, path))
        end
      end
    end
  rescue => error
    raise "Can't load theme - #{theme_path}\n#{error}"
  end

  def theme_file_path(theme_path, file_path)
    File.join(File.dirname(theme_path), file_path)
  end

  def check_one_of(message: '', expected: [], actual: '')
    unless expected.include?(actual)
      raise %(#{message}: ) +
            %(got '#{actual}', ) +
            %(expected one of: #{expected.map { |e| "'#{e}'" }.join(', ')})
    end
  end
end
