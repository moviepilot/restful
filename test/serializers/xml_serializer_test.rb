require File.dirname(__FILE__) + '/../test_helper.rb'

context "xml serializer" do
  setup do 
    Person.restful_publish(:name, :current_location, :pets, :wallet, :created_at)
    Pet.restful_publish(:name)
    Wallet.restful_publish(:contents)
  
    @person = Person.create(:name => "Joe Bloggs", :current_location => "Under a tree", :birthday => "1990-03-09")
    @pet = @person.pets.create(:species => "cat", :age => 200, :name => "mietze")
    @wallet = @person.wallet = Wallet.new(:contents => "an old photo, 5 euros in coins")
    @person.save
  end

  teardown do
    reset_config
  end

  specify "deserialize from rails style xml" do
    restful = @person.to_restful
    expected = restful.serialize(:xml)
    serializer = Restful::Serializers::XMLSerializer.new
    resource = serializer.deserialize(expected)    
    actual = serializer.serialize(resource)

    xml_should_eql(expected, actual)
  end
  
  specify "should serialize date type correctly" do
    xml_should_eql_fixture(@person.to_restful_xml(:birthday), "people", :joe_with_birthday)  
  end
  
  specify "should convert a NULL inner association such as person.wallet to a link with a null value" do
    @person.wallet = nil

    xml_should_eql_fixture(@person.to_restful_xml(:restful_options => { :expansion => :collapsed }), "people", :verbose_with_pets)    
  end
  
  specify "serialize to xml, rails style" do
    xml_should_eql_fixture(@person.to_restful_xml, "people", :with_pets_and_expanded_wallet)
  end
  
  specify "should serialize hashes correctly" do
    @person.pets.create(:species => "cat", :age => 100, :name => "motze")
    xml_should_eql_fixture(@person.to_restful_xml(:pets_ages_hash), "people", :hashy_person)
  end
    
  specify "should serialize collections correctly" do
    xml_should_eql_fixture(@person.pets.to_restful_xml, "pets", :pets_array)
  end
end