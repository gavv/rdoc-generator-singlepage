# RDoc::Generator::RSinglePage

Single page HTML5 generator for Ruby RDoc.

*Work in progress!*

## Features

* Generate single page HTML5 documentation suitable for offline use.
* Templates support using [Slim](http://slim-lang.com/).
* Themes support.
* Out of the box [SASS](http://sass-lang.com/) support.
* Filter classes or members by regex.

## Example

See example output [here](https://rbdoc.github.io/rdoc-generator-singlepage/example_html/). It was generated from the [`example.rb`](docs/example.rb) in the [`docs`](docs) directory.

Generate locally:

```
$ rake example
```

## Installation

From rubygems:

```
todo
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
$ rdoc -f rsinglepage --title "My Project"
```

Use custom directory and file name:

```
$ rdoc -f rsinglepage --output superdoc --rsp-filename superdoc.html
```

Specify theme name:

```
$ rdoc -f rsinglepage --rsp-theme default
```

Specify additional theme that may partially override default one:

```
$ rdoc -f rsinglepage --rsp-theme default --rsp-theme ./custom_theme.yml
```

Filter classes and members by regex:

```
$ rdoc -f rsinglepage --rsp-filter-classes '^Test.*' --rsp-filter-members '^test_.*'
```

#### From code

*todo*

#### From rake

*todo*

## Themes

*todo*

## License

* The source code is licensed under [MIT](LICENSE) license.
* Fonts have their own [licenses](data/rdoc-generator-singlepage/themes/common/fonts).
