require File.dirname(__FILE__) + '/../test_helper.rb'

context "basic types converter" do
  
  teardown { reset_config }
  
  specify "should be able to convert a hash to a resource map" do
    Person.restful_publish(:name)
    resource = { "zeperson" => @person = Person.create(:name => "fuddzle") }.to_restful
    resource.should.is_a?(Restful::ApiModel::Map)
    
    attrs = resource.simple_attributes
    attrs.size.should.== 1
    attrs.first.name.should.== "zeperson"
    
    attrs.first.value.values.first.value.== "fuddzle"
  end

  specify "should raise exception if not all array contents respond to .to_restful" do
    Person.restful_publish(:name)
    
    should.raise(TypeError) do
      [""].to_restful
    end
  end
  
  specify "should convert an empty array to a restful collection" do
    collection = [].to_restful
    collection.name.should.== "nil-classes"
  end  
  
  specify "should infer array name from first element class" do
    collection = [Pet.new].to_restful
    collection.name.should.== "pets"
  end
  
  specify "should infer array name from first element base_class if it is an active_record object" do
    collection = [Emu.new, Pet.new].to_restful
    collection.name.should.== "pets"
  end

  specify "should convert an array to a restful collection" do
    Person.restful_publish(:name)
    
    collection = [Person.create(:name => "Joe Bloggs")].to_restful
    collection.name.should.== "people"
    collection.value.size.should.== 1
    collection.value.first.simple_attributes.first.value.should.== "Joe Bloggs"
  end  
  
  specify "should set total_entries on the restful collection if the array responds to this" do
    Person.restful_publish(:name)
    people = PaginatedCollection.new([Person.create(:name => "Joe Bloggs")])
    people.total_entries = 1001

    collection = people.to_restful
    collection.total_entries.should.== 1001
  end
  
  specify "should set name on collection if array responds to .name and has this set" do
    Person.restful_publish(:name)
    people = PaginatedCollection.new()
    people.total_entries = 0
    people.name = "people"

    collection = people.to_restful
    collection.name.should.== "people"
  end
end

context "basic types converter :includes" do
  
  specify "should include extra attributes for hashes" do
    Person.restful_publish(:name)
    Pet.restful_publish(:name)
    
    @person = Person.create
    @pet = @person.pets.create(:name => "Mietze")

    map = { :pet => @pet }.to_restful(:include => :owner)
    map.values.first.name.should.== :pet
    map.values.first.value.values.map(&:name).should.include :owner
    
    Pet.restful_config.whitelisted.include?(:owner).should.equal false
  end
  
  specify "should include extra attributes for arrays" do
    Person.restful_publish(:name)
    Pet.restful_publish(:name)
    
    @person = Person.create
    @pet = @person.pets.create(:name => "Mietze")

    collection = [@pet].to_restful(:include => :owner)
    collection.value.first.values.map(&:name).should.include :owner
    
    Pet.restful_config.whitelisted.include?(:owner).should.equal false
  end
end