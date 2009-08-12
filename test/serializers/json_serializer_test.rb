require File.dirname(__FILE__) + '/../test_helper.rb'

context "json serializer" do
  
  setup do 
    Person.restful_publish(:name, :current_location, :pets, :wallet, :created_at)
    Pet.restful_publish(:name)
    Wallet.restful_publish(:contents)
    
    @person = Person.create(:name => "Joe Bloggs", :current_location => "Under a tree")
    @pet = @person.pets.create(:species => "cat", :age => 200, :name => "mietze")
    @wallet = @person.wallet = Wallet.new(:contents => "an old photo, 5 euros in coins")
    @person.save
  end
  
  teardown { reset_config }

  specify "serialize to json" do
    json_should_eql_fixture(@person.to_restful_json, "people", :bloggs)
  end
end
