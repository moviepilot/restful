require File.dirname(__FILE__) + '/../test_helper.rb'

context "json serializer" do

  setup do 
    Person.restful_publish(:name, :current_location, :pets, :wallet, :created_at)
    Pet.restful_publish(:name)
    Wallet.restful_publish(:contents)
    
    @person = Person.create(:name => "Joe Bloggs", :current_location => "Under a tree", :birthday => "2009-09-19")
    @pet = @person.pets.create(:species => "cat", :age => 200, :name => "mietze")
    @wallet = @person.wallet = Wallet.new(:contents => "an old photo, 5 euros in coins")
    @person.save
  end
  
  teardown { reset_config }

  specify "serialize to json" do
    json_should_eql_fixture(@person.to_restful_json, "people", :bloggs)
  end
  
  specify "should be able to serialize objects with empty collections" do
    @person.pets = []
    
    assert_nothing_raised do
      json_should_eql_fixture(@person.to_restful_json, "people", :bloggs_da_pet_hater)
    end
  end

  specify "should serialize date type correctly" do
    json_should_eql_fixture(@person.to_restful_json(:birthday), "people", :bloggs_with_birthday)  
  end
  
  specify "should not bug out on nil values in date fields" do
    person = Person.create :created_at => nil, :birthday => nil, :last_login => nil
    person.created_at = nil
    expected = "{\"birthday\":null,\"restful_url\":\"http://example.com:3000/people/#{person.to_param}\",\"last_login\":null,\"created_at\":null}"
    assert_nothing_raised do
      actual = person.to_restful_json([:created_at, :birthday, :last_login])
      json_should_eql(actual, expected)
    end
  end
  
  specify "should serialize hashes correctly" do
    @person.pets.create(:species => "cat", :age => 100, :name => "motze")
    json_should_eql_fixture(@person.to_restful_json(:pets_ages_hash), "people", :bloggs_with_pets_ages_hash)
  end
  
  specify "should render boolean values correctly" do
    json_should_eql_fixture(@person.to_restful_json(:has_pets), "people", :bloggs_with_has_pets)
    @person.pets = []
    @person.save!
    json_should_eql_fixture(@person.to_restful_json(:has_pets), "people", :bloggs_with_hasno_pets)
  end
  
  specify "should not ever use dashes as hash keys but underscores" do
    assert_nothing_raised do
      json_should_eql_fixture(@person.to_restful_json(:oldest_pet), "people", :bloggs_with_oldest_pet)
    end
  end
  
  specify "should serialize collections correctly" do
    json_should_eql_fixture(@person.pets.to_restful_json, "pets", :pets_array)
  end    
  
  specify "should be able to serialize collections with total entries info" do
    pets = PaginatedCollection.new(@person.pets)
    pets.total_entries = 1001
    
    json_should_eql_fixture(pets.to_restful_json, "pets", :pets_array_with_total_entries)
  end
  
  specify "should be able to serialize a map" do
    Person.restful_publish(:name)
    json_should_eql_fixture({ "total_hits" => 1, "a_person" => @person }.to_restful_json, "people", :hash_with_person)
  end
  
  specify "should be able to serialize a map with arrays as values" do
    Person.restful_publish(:name)
    json_should_eql_fixture({ "total_hits" => 2, "people" => [ @person, @person ] }.to_restful_json, "people", :hash_with_people)
  end

  specify 'should serialize a hash with include option correctly - the include option should be passed to the values' do
    Person.restful_publish(:name)
    Wallet.restful_publish(:contents)
    
    json = {:person => @person}.to_restful_json(:include => :wallet)
    json_should_eql_fixture(json, "people", :hash_with_rich_person)
  end
end