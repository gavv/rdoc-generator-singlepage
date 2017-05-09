require 'json'

# JSONWriter builds JSON file and copies it to the output directory.
class JSONWriter
  def initialize(options)
    @options = options
  end

  def write(data)
    json = JSON.pretty_generate(data)

    File.open(@options.sf_jsonfile, 'w') do |file|
      file.write(json)
    end
  end
end
