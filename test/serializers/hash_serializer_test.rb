require File.dirname(__FILE__) + '/../test_helper.rb'

context "hash serializer" do
  
  specify "should be able to convert null links" do
    Person.restful_publish(:wallet_restful_url)
    person = Person.create
    person.to_restful_hash[:wallet].should.== nil
  end
end