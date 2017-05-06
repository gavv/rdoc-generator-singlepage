require 'minitest'
require 'minitest/autorun'

require 'rdoc/generator/theme_loader'

require_relative 'themes'

class TestThemeLoader < MiniTest::Test
  class Options
    attr_accessor :sf_themes
    attr_accessor :sf_prefix
  end

  def subset?(outer, inner)
    if outer.is_a?(Hash)
      inner.each do |k, v|
        return false unless subset? outer[k], v
      end
    elsif outer.is_a?(Array)
      inner.each do |i|
        return false unless outer.any? do |o|
          subset? o, i
        end
      end
    else
      return false unless outer == inner
    end
    return true
  end

  def load_themes(themes, prefix)
    options = Options.new
    options.sf_themes = []
    options.sf_prefix = prefix

    themes.each do |t|
      options.sf_themes << t.theme_path
    end

    theme_loader = ThemeLoader.new(options)
    theme_loader.load
  end

  def check_themes_with_prefix(themes: [], in_prefix: '', out_prefix: '')
    theme, files = load_themes themes, in_prefix

    themes.each do |t|
      assert subset? theme, t.expected_hash(out_prefix)
      assert subset? files, t.expected_files
    end
  end

  def check_themes(themes)
    check_themes_with_prefix(
      themes:     themes,
      in_prefix:  '',
      out_prefix: '',
    )
    check_themes_with_prefix(
      themes:     themes,
      in_prefix:  '/test_prefix',
      out_prefix: '/test_prefix/',
    )
    check_themes_with_prefix(
      themes:     themes,
      in_prefix:  '/test_prefix/',
      out_prefix: '/test_prefix/',
    )
  end

  def test_theme1
    check_themes([
      Theme1.new,
    ])
  end

  def test_theme2
    check_themes([
      Theme2.new,
    ])
  end

  def test_theme1_theme2
    check_themes([
      Theme1.new,
      Theme2.new,
    ])
  end
end
