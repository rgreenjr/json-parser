require 'rubygems'
require 'treetop'
Treetop.load 'json'

file = 'test/test_file5.json'
parser = JsonParser.new
result = parser.parse(IO.read(file))
raise "Failed to parse JSON file: " + parser.failure_reason unless result
p result.to_ruby
