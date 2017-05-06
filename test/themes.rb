require 'fileutils'

class BasicTheme
  def initialize(name)
    @dir = Dir.mktmpdir
    @path = File.join(@dir, name)
  end

  def theme_path
    @path
  end

  def file_path(name)
    File.join(@dir, name)
  end

  def write_file(name, data)
    path = file_path(name)
    FileUtils.mkpath(File.dirname(path))
    File.write(path, data)
  end
end

class Theme1 < BasicTheme
  def initialize
    super 'theme1.yml'

    write_file 'theme1.yml', theme_yaml

    write_file 'dir1/style1a.css', ''
    write_file 'dir2/style1b.sass', ''
    write_file 'dir2/style1c.scss', ''

    write_file 'dir1/script1a.js', ''
    write_file 'dir2/script1b.js', ''

    write_file 'dir1/font1a.ttf', ''
    write_file 'dir2/font1b.ttf', ''

    write_file 'dir1/head1a.html', '<style>h1a</style>'
    write_file 'dir2/head1b.html', '<style>h1b</style>'

    write_file 'dir1/body1a.html', '<p>b1a</p>'
    write_file 'dir2/body1b.html', '<p>b1b</p>'
    write_file 'dir1/body1c.html', '<p>b1c</p>'
    write_file 'dir2/body1d.html', '<p>b1d</p>'
  end

  def theme_yaml
    <<END
head:
  styles:
    -
      file: dir1/style1a.css
    -
      file: dir2/style1b.sass
    -
      file: dir2/style1c.scss
  scripts:
    -
      file: dir1/script1a.js
    -
      file: dir2/script1b.js
  fonts:
    -
      file: dir1/font1a.ttf
      family: Family1a
    -
      file: dir2/font1b.ttf
      family: Family1b
  html:
    -
      file: dir1/head1a.html
    -
      file: dir2/head1b.html
body:
  header:
    -
      file: dir1/body1a.html
    -
      file: dir2/body1b.html
  footer:
    -
      file: dir1/body1c.html
    -
      file: dir2/body1d.html
END
  end

  def expected_files
    [
      { dst_name: 'style1a.css', src_path: file_path('dir1/style1a.css') },
      { dst_name: 'style1b.css' },
      { dst_name: 'style1c.css' },

      { dst_name: 'script1a.js', src_path: file_path('dir1/script1a.js') },
      { dst_name: 'script1b.js', src_path: file_path('dir2/script1b.js') },

      { dst_name: 'font1a.ttf', src_path: file_path('dir1/font1a.ttf') },
      { dst_name: 'font1b.ttf', src_path: file_path('dir2/font1b.ttf') },
    ]
  end

  def expected_hash(prefix)
    {
      :head => {
        :styles => [
          { :url => "#{prefix}style1a.css" },
          { :url => "#{prefix}style1b.css" },
          { :url => "#{prefix}style1c.css" },
        ],
        :scripts => [
          { :url => "#{prefix}script1a.js" },
          { :url => "#{prefix}script1b.js" },
        ],
        :fonts => [
          { :url => "#{prefix}font1a.ttf", :family => 'Family1a' },
          { :url => "#{prefix}font1b.ttf", :family => 'Family1b' },
        ],
        :html => [
          { :data => '<style>h1a</style>' },
          { :data => '<style>h1b</style>' },
        ],
      },
      :body => {
        :header => [
          { :data => '<p>b1a</p>' },
          { :data => '<p>b1b</p>' },
        ],
        :footer => [
          { :data => '<p>b1c</p>' },
          { :data => '<p>b1d</p>' },
        ],
      }
    }
  end
end

class Theme2 < BasicTheme
  def initialize
    super 'theme2.yml'

    write_file 'theme2.yml', theme_yaml

    write_file 'style2a.css', ''
    write_file 'script2a.js', ''
    write_file 'font2a.ttf', ''
    write_file 'head2a.html', '<style>h2a</style>'
    write_file 'body2a.html', '<p>b2a</p>'
    write_file 'body2b.html', '<p>b2b</p>'
  end

  def theme_yaml
    <<END
head:
  styles:
    -
      file: style2a.css
  scripts:
    -
      file: script2a.js
  fonts:
    -
      file: font2a.ttf
      family: Family2a
  html:
    -
      file: head2a.html
body:
  header:
    -
      file: body2a.html
  footer:
    -
      file: body2b.html
END
  end

  def expected_files
    [
      { dst_name: 'style2a.css', src_path: file_path('style2a.css') },
      { dst_name: 'script2a.js', src_path: file_path('script2a.js') },
      { dst_name: 'font2a.ttf',  src_path: file_path('font2a.ttf') },
    ]
  end

  def expected_hash(prefix)
    {
      :head => {
        :styles => [
          { :url => "#{prefix}style2a.css" },
        ],
        :scripts => [
          { :url => "#{prefix}script2a.js" },
        ],
        :fonts => [
          { :url => "#{prefix}font2a.ttf", :family => 'Family2a' },
        ],
        :html => [
          { :data => '<style>h2a</style>' },
        ],
      },
      :body => {
        :header => [
          { :data => '<p>b2a</p>' },
        ],
        :footer => [
          { :data => '<p>b2b</p>' },
        ],
      }
    }
  end
end
