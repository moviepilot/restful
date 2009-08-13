require 'rubygems'
require 'ruby-debug'
require 'active_support'
require 'active_record'
require 'action_controller'
require 'test/spec'
require 'mocha'
require 'hpricot'
require 'xmlsimple'
require 'yajl'
require 'pathname'
require 'stringio'

plugin_test = Pathname.new(File.dirname(__FILE__))
plugin_root = plugin_test.join '..'
plugin_lib = plugin_root.join 'lib'

$:.unshift plugin_lib, plugin_test

RAILS_ENV = "test"
RAILS_ROOT = plugin_root # fake the rails root directory.
RESTFUL_ROOT = plugin_root

ActiveRecord::Base.logger = Logger.new(STDERR)
ActiveRecord::Base.logger.level = Logger::ERROR
ActiveRecord::Base.colorize_logging = false
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile  => ":memory:")

silence_stream(STDOUT) do
  ActiveRecord::Schema.define do
    
    create_table :pets do |t|
      t.integer :age, :default => 10
      t.string :name
      t.integer :species
      t.integer :person_id
      
      t.timestamp :created_at
      t.timestamp :updated_at
    end

    create_table :people do |t|
      t.string :name
      t.string :current_location
      t.string :biography

      t.timestamp :created_at      
      t.timestamp :updated_at
    end

    create_table :wallets do |t|
      t.string :person_id
      t.string :contents
      
      t.timestamp :created_at
      t.timestamp :updated_at
    end
  end
end

require plugin_root.join 'init'
require 'fixtures/models/pet'
require 'fixtures/models/wallet'
require 'fixtures/models/person'

Restful::Rails.api_hostname = "http://example.com:3000"

#
#  Helper methods
#
def reset_config
  Person.restful_config = Restful.cfg
  Pet.restful_config = Restful.cfg  
  Wallet.restful_config = Restful.cfg  
end

def xml_cmp(actual, expected)
  eq_all_but_zero = Object.new.instance_eval do
    def ==(other)
      Integer(other) == 0 ? false : true
    end
    self
  end
  
  actual = XmlSimple.xml_in(actual.to_s, 'normalisespace' => eq_all_but_zero) 
  expected = XmlSimple.xml_in(expected.to_s, 'normalisespace' => eq_all_but_zero) 
  actual == expected
end

def json_cmp(actual, expected)
  actual = Yajl::Parser.parse(actual)
  expected = Yajl::Parser.parse(expected)
  puts_hash_diff actual, expected
  actual == expected
end

def puts_hash_diff(hash1, hash2, indent = 0)
  return if hash1 == hash2
  
  (hash1.keys + hash2.keys).uniq.each do |key|
    next if hash1[key] == hash2[key]
    print "  "*indent
    if hash1[key].is_a? Hash or hash2[key].is_a? Hash
      puts "=== #{key} is a Hash ==="
      puts_hash_diff(hash1[key] || {}, hash2[key] || {}, indent+2)
    else
      printf "%-#{20-indent}s %#{50-indent}s != %-50s\n", key[0..19], hash1[key], hash2[key]
    end
  end
end

def xml_should_eql_fixture(actual, name, key)
  expected = Hpricot(xml_fixture(name)[key])
  actual = Hpricot(actual)
  
  xml_should_eql(actual, expected)
end

# doing this tests that the content is the same regardless of attribute order etc. 
def xml_should_eql(actual, expected)
  same = xml_cmp(actual, expected)
  actual.should.== expected unless same  
end

def json_should_eql_fixture(actual, name, key)  
  expected = json_fixture(name)[key]
  json_should_eql(actual, expected)
end

# doing this tests that the content is the same regardless of attribute order etc. 
def json_should_eql(actual, expected)
  same = json_cmp(actual, expected)
  actual.should.== expected unless same 
end

def file_fixture(name)
  template = File.open(RESTFUL_ROOT.join("test", "fixtures", name)).read
  fixture = ERB.new(template).result(binding)
  yaml = YAML.load(fixture)
  yaml.symbolize_keys
end

def xml_fixture(name); file_fixture("#{ name }.xml.yaml"); end
def json_fixture(name); file_fixture("#{ name }.json.yaml"); end