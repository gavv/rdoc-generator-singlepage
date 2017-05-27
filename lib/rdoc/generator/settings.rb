require 'pathname'
require 'rubygems'

# Predefined configuration.
module Settings
  DEFAULT_HTMLFILE = 'index.html'.freeze
  DEFAULT_TEMPLATE = 'onepage'.freeze
  DEFAULT_THEME    = 'light'.freeze

  def self.list_file_names(dir, ext)
    data_files(dir, "*#{ext}").map do |file|
      File.basename(file, ext)
    end
  end

  def self.find_file(dir, ext, name)
    if name.include? '/'
      File.absolute_path name
    else
      data_files(dir, "*#{ext}").each do |file|
        return file if File.basename(file, ext) == name
      end
    end
  end

  def self.data_files(subdir, pattern)
    files = []

    data_dirs(subdir).each do |dir|
      pattern = File.join dir, pattern

      Dir[pattern].sort.map do |file|
        files << file
      end
    end

    files.uniq
  end

  def self.data_dirs(subdir)
    gemdirs = [
      Pathname.new(File.join(File.dirname(__FILE__), '../../..')).cleanpath.to_s
    ]
    Gem::Specification.each do |spec|
      gemdirs << spec.full_gem_path
    end

    datadirs = gemdirs.map do |dir|
      File.join dir, 'data', 'rdoc-generator-solarfish', subdir
    end
    datadirs = datadirs.select do |dir|
      File.exist? dir
    end

    datadirs.uniq
  end
end
