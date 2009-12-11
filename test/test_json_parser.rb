require 'rubygems'
require 'test/unit'
require 'treetop'
Treetop.load 'json'

class TestJsonParser < Test::Unit::TestCase

  def setup
    @parser = JsonParser.new
    @dir = File.dirname(__FILE__)
  end

  def test_true
    @parser.root = 'true'
    assert_equal(true, assert_parse('true').to_ruby)
    assert_parse_fail('truely')
  end

  def test_null
    @parser.root = 'null'
    assert_equal(nil, assert_parse('null').to_ruby)
    assert_parse_fail('nullify')
  end

  def test_false
    @parser.root = 'false'
    assert_equal(false, assert_parse('false').to_ruby)
    assert_parse_fail('falsely')
  end

  def test_number
    @parser.root = 'number'
    assert_equal(42, assert_parse("42").to_ruby)
    assert_equal(-13, assert_parse("-13").to_ruby)
    assert_equal(3.1415, assert_parse("3.1415").to_ruby)
    assert_equal(0.1415, assert_parse(".1415").to_ruby)
    assert_equal(-0.01, assert_parse("-0.01").to_ruby)
    assert_equal(0.2e1, assert_parse("0.2e1").to_ruby)
    assert_equal(0.2e+1, assert_parse("0.2e+1").to_ruby)
    assert_equal(0.2e-1, assert_parse("0.2e-1").to_ruby)
    assert_equal(0.2e1, assert_parse("0.2e1").to_ruby)
    assert_parse_fail("$1,000")
    assert_parse_fail("1_000")
    assert_parse_fail("1K")
  end
  
  def test_regular_char
    @parser.root = 'regular_char'
    assert_equal('a', assert_parse("a").to_s)
    assert_equal('#', assert_parse("#").to_s)
    assert_equal('C', assert_parse("C").to_s)
    assert_equal('&', assert_parse("&").to_s)
    assert_equal('a', assert_parse("a").to_s)
    assert_parse_fail("\\t")
    assert_parse_fail("\\")
  end
  
  # def test_escaped_char
  #   @parser.root = 'escaped_char'
  #   p assert_parse("\\f")
  #   assert_equal('\f', assert_parse("\\f").to_s)
  #   assert_equal('\n', assert_parse("\\n").to_s)
  #   assert_equal('\b', assert_parse("\\b").to_s)
  #   assert_equal('\r', assert_parse("\\r").to_s)
  #   assert_equal('\t', assert_parse("\\t").to_s)
  #   assert_equal('\\\\', assert_parse("\\\\").to_s)
  #   assert_parse_fail('"a"')
  #   assert_parse_fail('"#"')
  #   assert_parse_fail('"\\i"')
  # end
  
  def test_unicode_char
    @parser.root = 'unicode_char'
    assert_equal('a', @parser.parse(%Q{\\u#{"%04X" % ?a}}).to_s)
    assert_equal('b', @parser.parse('\\u0062').to_s)
    assert_parse_fail('"\\uCAFEE"')
    assert_parse_fail('"\uCAFEE"')
  end
  
  def test_string
    @parser.root = 'string'
    assert_equal('string', assert_parse(%q{"string"}).to_ruby)
    assert_equal('string with spaces internally', assert_parse(%q{"string with spaces internally"}).to_ruby)
    assert_equal('   string with leading spaces', assert_parse(%q{"   string with leading spaces"}).to_ruby)
    assert_equal('string with trailing spaces   ', assert_parse(%q{"string with trailing spaces   "}).to_ruby)
    assert_equal('string with numbers and dashes -- 123, 456', assert_parse(%q{"string with numbers and dashes -- 123, 456"}).to_ruby)
    assert_equal('embedded single quote in str"ing', assert_parse(%q{"embedded single quote in str\"ing"}).to_ruby)
    assert_equal("", assert_parse(%q{""}).to_ruby)
    assert_equal("JSON", @parser.parse(%q{"JSON"}).to_ruby)
    assert_equal("\n", @parser.parse(%q{"\\n"}).to_ruby)
    assert_equal("new\nline", @parser.parse(%q{"new\\nline"}).to_ruby)
    assert_equal("carriage return\rnew line\n", @parser.parse(%q{"carriage return\\rnew line\\n"}).to_ruby)
    assert_equal('this is the word cat', @parser.parse('"this is the word \\u0063\\u0061\\u0074"').to_s)
    assert_equal("a", assert_parse(%Q{"\\u#{"%04X" % ?a}"}).to_ruby)
    assert_parse_fail(%q{"})
  end

  def test_pair
    @parser.root = 'pair'
    assert_equal('bar', assert_parse('"foo" : "bar"').to_ruby['foo'])
    assert_equal(123, assert_parse('"foo" : 123').to_ruby['foo'])
    assert_equal(true, assert_parse('"foo" : true').to_ruby['foo'])
    assert_equal(nil, assert_parse('"foo" : null').to_ruby['foo'])
    assert_equal(false, assert_parse('"foo" : false').to_ruby['foo'])
    assert_equal([1, 2, 3], assert_parse('"foo" : [1, 2, 3]').to_ruby['foo'])
    assert_equal({"hello" => "goodbye"}, assert_parse('"foo" : { "hello" : "goodbye" }').to_ruby['foo'])
  end

  def test_array
    @parser.root = 'array'
    assert_equal([], assert_parse('[ ]').to_ruby)
    assert_equal([1, 2, 3], assert_parse('[1, 2, 3]').to_ruby)
    assert_equal(["a", "b", "c"], assert_parse('["a", "b", "c"]').to_ruby)
    assert_equal([true, false, nil], assert_parse('[true, false, null]').to_ruby)
    assert_equal([1, ["a", [true], "c"], 2], assert_parse('[1, ["a", [true], "c"], 2]').to_ruby)
    assert_equal(Array.new, @parser.parse(%q{[]}).to_ruby)
    assert_equal(["JSON", 3.1415, true], @parser.parse(%q{["JSON", 3.1415, true]}).to_ruby)
    assert_equal([1, [2, [3]]], @parser.parse(%q{[1, [2, [3]]]}).to_ruby)
    assert_parse_fail("[")
    assert_parse_fail("[1,,2]")
  end

  def test_object
    @parser.root = 'object'
    assert_equal(Hash.new, assert_parse('{}').to_ruby)
    assert_equal(Hash.new, assert_parse('{ }').to_ruby)
    assert_equal({ "foo" => 123 }, assert_parse('{ "foo" : 123 }').to_ruby)
    assert_equal({ "foo" => true }, assert_parse('{ "foo" : true }').to_ruby)
    assert_equal({ "foo" => nil }, assert_parse('{ "foo" : null }').to_ruby)
    assert_equal({ "foo" => false }, assert_parse('{ "foo" : false }').to_ruby)
    assert_equal({ "foo" => "this is a string" }, assert_parse('{ "foo" : "this is a string" }').to_ruby)
    assert_equal({ "foo" => { "bar" => 123 } }, assert_parse('{ "foo" : { "bar" : 123 } }').to_ruby)
    assert_equal({"JSON" => 3.14, "data" => true}, @parser.parse(%q{{"JSON": 3.14, "data": true}}).to_ruby)
    assert_parse_fail("{")
    assert_parse_fail(%q{{"key": true false}})
  end
  
  def test_json
    @parser.root = 'json'
    assert_equal(Array.new, assert_parse('[]').to_ruby)    
  end

  def test_file1
    result = assert_parse_file('test_file1.json').to_ruby
    assert_equal("John", result["firstName"])
    assert_equal("New York", result["address"]["city"])
    assert_equal("646 123-4567", result["phoneNumbers"].last)
  end

  def test_file2
    result = assert_parse_file('test_file2.json').to_ruby
    assert_equal("http://www.example.com/image/481989943", result["Image"]["Thumbnail"]["Url"])
    assert_equal(234, result["Image"]["IDs"][2])
  end

  def test_file3
    result = assert_parse_file('test_file3.json').to_ruby
    assert_equal("SGML", result["glossary"]["GlossDiv"]["GlossList"]["GlossEntry"]["ID"])
    assert_equal("GML", result["glossary"]["GlossDiv"]["GlossList"]["GlossEntry"]["GlossDef"]["GlossSeeAlso"].first)
  end

  def test_file4
    result = assert_parse_file('test_file4.json').to_ruby
    assert_equal("on", result["widget"]["debug"])
    assert_equal(500.0, result["widget"]["window"]["height"])
    assert_equal(500.0e1, result["widget"]["window"]["width"])
    assert_equal("sun1.opacity = (sun1.opacity / 100) * 90;", result["widget"]["text"]["onMouseUp"])
  end

  def test_file5
    result = assert_parse_file('test_file5.json').to_ruby
    assert_equal("cofax", result["web-app"]["servlet"][0]["init-param"]["dataStoreName"])
    assert_equal("/content/admin/remove?cache=pages&id=", result["web-app"]["servlet"][4]["init-param"]["removePageCache"])
  end

  def test_print
    text = String.new
    File.open(File.join(@dir, 'test_file5.json'), 'r') { |f| text = f.read }
    result = @parser.parse(text)
    puts @parser.terminal_failures.join("\n") unless result
    assert !result.nil?
    # puts result
  end

  def assert_parse(input)
    result = @parser.parse(input)
    unless result
      # puts @parser.terminal_failures.join("\n")
      puts @parser.failure_reason
      # p @parser unless result
    end
    assert !result.nil?
    result
  end

  def assert_parse_fail(input)
    result = @parser.parse(input)
    assert result.nil?
    result
  end

  def assert_parse_file(file)
    text = String.new
    File.open(File.join(@dir, file), 'r') { |f| text = f.read }
    assert_parse(text)
  end

end