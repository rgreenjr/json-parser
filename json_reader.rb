require 'rubygems'
require 'treetop'

dir = File.expand_path(File.dirname(__FILE__))

Treetop.load(File.expand_path("#{File.dirname(__FILE__)}/json"))

class JsonReader

  def self.load(file)
    @parser = JsonParser.new
    text = String.new
    File.open(file, 'r') {|f| text = f.read}
    result = @parser.parse(text)
    raise "Failed to parse JSON file: " + @parser.failure_reason unless result
    result.to_ruby
  end

end

p JsonReader.load(File.join(dir, "test/test_file5.json"))