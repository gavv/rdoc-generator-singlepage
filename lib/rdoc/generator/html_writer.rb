# frozen_string_literal: true

require 'fileutils'

# HTMLWriter builds HTML file from a template and copies HTML and
# theme files to the output directory.
class HTMLWriter
  def initialize(options)
    @options = options
  end

  def write(data, theme_files, template)
    html = template.render(data)
    install_theme(theme_files)
    install_html(html)
  end

  private

  def install_theme(theme_files)
    theme_files.each do |file|
      if file[:dst_name]
        if file[:src_path]
          FileUtils.copy_file(file[:src_path], file[:dst_name])
        elsif file[:data]
          File.write(file[:dst_name], file[:data])
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
