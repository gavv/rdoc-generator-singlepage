require 'json'

# JSONBuilder builds JSON file and installs it to the output directory.
class JSONBuilder
  def initialize(options)
    @options = options
  end

  def build(scope)
    json = JSON.pretty_generate(scope)

    File.open(@options.sf_jsonfile, 'w') do |file|
      file.write(json)
    end
  end
end
