# RDoc::Generator::SolarFish

[![Build Status](https://travis-ci.org/rbdoc/rdoc-generator-solarfish.svg?branch=master)](https://travis-ci.org/rbdoc/rdoc-generator-solarfish)

Single page HTML5 generator for Ruby RDoc.

## Features

* Generate single page HTML5 documentation suitable for offline use.
* Templates support using [Slim](http://slim-lang.com/).
* Themes support.
* Out of the box [Sass](http://sass-lang.com/) and SCSS support.
* Filter classes or members by regex.

## Example

See example output:

* [HTML](https://rbdoc.github.io/rdoc-generator-solarfish/example_output/)
* [JSON](docs/example_output/index.json)

It was generated from the [`example.rb`](docs/example.rb) in the [`docs`](docs) directory.

Generate locally:

```
$ rake install
$ rake example
```

## Installation

From rubygems:

```
TODO
```

From sources:

```
$ rake install
```

## Usage

#### From command line

Display all supported command line options:

```
$ rdoc --help
```

Generate documentation under the `doc/` directory:

```
$ rdoc -f solarfish --title "My Project"
```

Use custom directory and file name:

```
$ rdoc -f solarfish --output superdoc --sf-htmlfile superdoc.html
```

Additionally dump JSON:

```
$ rdoc -f solarfish --output superdoc --sf-htmlfile superdoc.html --sf-jsonfile superdoc.json
```

Specify template name:

```
$ rdoc -f solarfish --sf-template onepage
```

Specify theme name:

```
$ rdoc -f solarfish --sf-theme light
```

Specify additional theme that may partially override default one:

```
$ rdoc -f solarfish --sf-theme light --sf-theme ./custom_theme.yml
```

Filter classes and members by regex:

```
$ rdoc -f solarfish --sf-filter-classes '^Test.*' --sf-filter-members '^test_.*'
```

#### From code

```ruby
require 'rdoc/rdoc'

options = RDoc::Options.new
options.setup_generator 'solarfish'

options.files = ['input_file.rb']
options.op_dir = 'output_dir'
options.title = 'Page title'

options.sf_htmlfile = 'output_file.html'
options.sf_jsonfile = 'output_file.json'

options.sf_prefix = '/url_prefix'

options.sf_template = '/path/to/template.slim'
options.sf_themes = ['/path/to/theme.yml']

options.sf_filter_classes = '^Test.*'
options.sf_filter_members = '^test_.*'

rdoc = RDoc::RDoc.new
rdoc.document options
```

## Configuration

#### Templates

The HTML page layout is defined by a [Slim](http://slim-lang.com/) template.

Only one template is available out of the box:

* ["onepage" template](https://github.com/rbdoc/rdoc-generator-solarfish/blob/master/data/rdoc-generator-solarfish/templates/onepage.slim)

You can configure what template to use with the `--sf-template` option. Its value may be either a path or a name. In the later case, the template is searched in all locally installed gems that provide `data/rdoc-generator-solarfish/templates` directory.

#### Themes

The HTML page style is defined by a YAML theme. A theme file may contain Sass and SCSS stylesheet files and font files.

Only one theme is available out of the box:

* ["light" theme](https://github.com/rbdoc/rdoc-generator-solarfish/blob/master/data/rdoc-generator-solarfish/themes/light.yml)

You can configure what theme to use with the `--sf-theme` option. Its value may be either a path or a name. In the later case, the theme is searched in all locally installed gems that provide `data/rdoc-generator-solarfish/themes` directory.

Multiple themes can be used simultaneously. In this case, each next theme may add more stylesheet or font files and overrides previous themes.

## Development

Install development dependencies:

```
$ bundle
```

Run tests:

```
$ rake test
```

Run linters:

```
$ rake rubocop
```

Automatically fix some linter errors:

```
$ rake rubocop:auto_correct
```

## License

* The source code is licensed under [MIT](LICENSE) license.
* [Fonts](data/rdoc-generator-solarfish/themes/common/fonts) and [syntax themes](data/rdoc-generator-solarfish/themes/common/syntax) have their own licenses.
