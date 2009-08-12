require File.dirname(__FILE__) + '/../test_helper.rb'

context "params serializer" do

  setup do 
    Person.restful_publish(:name, :current_location, :pets, :wallet, :created_at)
    Pet.restful_publish(:name)
    Wallet.restful_publish(:contents)
  
    @person = Person.create(:name => "Joe Bloggs", :current_location => "Under a tree")
    @pet = @person.pets.create(:species => "cat", :age => 200, :name => "mietze")
    @wallet = @person.wallet = Wallet.new(:contents => "an old photo, 5 euros in coins")
    @person.save
  end

  teardown do
    reset_config
  end

  specify "serialize to xml, atom style" do
    xml_should_eql_fixture(@person.to_restful_atom_like, "people", :atom_person)
  end
  
  specify "deserialize from atom style xml" do
    restful = @pet.to_restful
    expected = restful.serialize(:atom_like)
    serializer = Restful::Serializers::AtomLikeSerializer.new
    resource = serializer.deserialize(expected)
    actual = serializer.serialize(resource)
  
    xml_should_eql(expected, actual)
  end
end