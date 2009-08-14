require File.dirname(__FILE__) + '/../test_helper.rb'

context "basic types converter" do
  teardown { reset_config }
  
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

  specify "should convert an array to a restful collection" do
    Person.restful_publish(:name)
    
    collection = [Person.create(:name => "Joe Bloggs")].to_restful
    collection.name.should.== "people"
    collection.value.size.should.== 1
    collection.value.first.simple_attributes.first.value.should.== "Joe Bloggs"
  end  
end