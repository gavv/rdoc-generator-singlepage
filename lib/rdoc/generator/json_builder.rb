require 'json'

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
