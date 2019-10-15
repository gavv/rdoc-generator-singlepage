# frozen_string_literal: true

require 'fileutils'
require 'yaml'
require 'sass'

require_relative 'settings'

# ThemeLoader reads theme files from `.yml' files and builds a hash that
# will be passed to HTML template or written to JSON file, and a list
# of theme files to be installed along with the HTML file.
class ThemeLoader
  def self.themes_list
    Settings.list_file_names 'themes', '.yml'
  end

  def self.theme_path(name)
    Settings.find_file 'themes', '.yml', name
  end

  def initialize(options)
    @options = options
  end

  def load
    theme = {
      head: {
        styles: [],
        fonts: [],
        scripts: [],
        html: []
      },
      body: {
        header: [],
        footer: []
      }
    }

    theme_files = []

    @options.sf_themes.each do |theme_path|
      load_theme(theme, theme_files, theme_path)
    end

    build_files(theme_files)

    [theme, theme_files]
  end

  private

  def load_theme(theme, theme_files, theme_path)
    config = YAML.load_file theme_path

    config.each do |section, content|
      check_one_of(
        message: 'Unexpected section in theme config',
        expected: %w[head body],
        actual: section
      )

      case section
      when 'head'
        content.each do |key, files|
          check_one_of(
            message: "Unexpected key in 'head'",
            expected: %w[styles fonts scripts html],
            actual: key
          )
          section = key.to_sym
          files.each do |file_info|
            path = theme_file(theme_path, file_info['file'])
            case section
            when :styles, :scripts, :fonts
              name = File.basename(path)
              fh = {
                url: theme_url(name)
              }
              fh[:family] = file_info['family'] if section == :fonts
              fp = {
                src_path: path,
                dst_name: name,
                dst_info: fh
              }
            when :html
              fh = {
                data: File.read(path)
              }
            end
            theme[:head][section] << fh
            theme_files << fp if fp
          end
        end

      when 'body'
        content.each do |key, files|
          check_one_of(
            message: "Unexpected key in 'body'",
            expected: %w[header footer],
            actual: key
          )
          files.each do |file_info|
            path = theme_file(theme_path, file_info['file'])
            fh = {
              data: File.read(path)
            }
            theme[:body][key.to_sym] << fh
          end
        end
      end
    end
  rescue StandardError => e
    raise "Can't load theme - #{theme_path}\n#{e}"
  end

  def build_files(theme_files)
    theme_files.each do |file|
      ext = File.extname file[:src_path]
      build_css_file file, ext if %w[.sass .scss].include? ext
    end
  end

  def build_css_file(file, ext)
    options = {
      cache: false,
      style: :default
    }

    options[:syntax] = if ext == '.sass'
                         :sass
                       else
                         :scss
                       end

    input_data = File.read(file[:src_path])
    renderer = Sass::Engine.new(input_data, options)
    output_data = renderer.render

    file.delete(:src_path)
    file[:dst_name] = File.basename(file[:dst_name], '.*') + '.css'
    file[:dst_info][:url] = theme_url(file[:dst_name])
    file[:data] = output_data
  end

  def theme_file(theme_path, file_path)
    File.join(File.dirname(theme_path), file_path)
  end

  def theme_url(name)
    url = @options.sf_prefix || ''
    url += '/' if !url.empty? && !url.end_with?('/')
    url + name
  end

  def check_one_of(message: '', expected: [], actual: '')
    unless expected.include?(actual)
      raise %(#{message}: ) +
            %(got '#{actual}', ) +
            %(expected one of: #{expected.map { |e| "'#{e}'" }.join(', ')})
    end
  end
end
