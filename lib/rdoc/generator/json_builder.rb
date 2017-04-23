require 'json'

class JSONBuilder
  def initialize(options)
    @options = options
  end

  def build(classes)
    json = JSON.pretty_generate(classes)

    File.open(@options.sf_jsonfile, 'w') do |file|
      file.write(json)
    end
  end
end
