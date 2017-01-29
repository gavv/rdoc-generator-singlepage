# RDoc::Generator::RSinglePage

Single page HTML5 generator for Ruby RDoc.

*Work in progress!*

## Features

* Generate single page HTML5 documentation suitable for offline use.
* Themes support.
* Exclude classes or members by regex.
* Group class members by regex.

## Example output

Example output is available [online](https://rbdoc.github.io/rdoc-generator-singlepage/example_html/). It was generated from the [`example.rb`](docs/example.rb) in the [`docs`](docs) directory.

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

## Using from command line

Display all supported command line options:

```
$ rdoc --help
```

Generate documentation under the `doc/` directory:

```
$ rdoc -f rsinglepage
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

Generate documentation only for tests, and group members by regex:

```
$ rdoc -f rsinglepage                          \
     --rsp-filter-classes '^Test.*'            \
     --rsp-filter-members '^test_.*'           \
     --rsp-group-members 'test_([^_]+)_.*'
```

## Using from code

*todo*

## Adding themes

*todo*

## License

MIT
