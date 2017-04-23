require 'fileutils'

class HTMLBuilder
  def initialize(options)
    @options = options
  end

  def build(classes, theme, template)
    html = template.render(
      title:   @options.title,
      theme:   theme,
      classes: classes
    )

    install_theme(theme)
    install_html(html)
  end

  private

  def install_theme(theme)
    theme[:head].values.each do |files|
      files.each do |file|
        if file[:dst_name]
          if file[:src_path]
            FileUtils.copy_file(file[:src_path], file[:dst_name])
          elsif file[:data]
            File.write(file[:dst_name], file[:data])
          end
        end
      end
    end
  end

  def install_html(html)
    File.open(@options.sf_htmlfile, 'w') do |file|
      file.write(html)
    end
  end
end
