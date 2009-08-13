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
  
  specify "should be able to serialize objects empty collections" do
    @person.pets = []
    expected = 
      {
        :name => "Joe Bloggs",
        :current_location => "Under a tree",
        :created_at => @person.created_at,
        :wallet_attributes=>{:contents=>"an old photo, 5 euros in coins"}
      }

    assert_nothing_raised do
      actual = @person.to_restful.serialize :params
      actual.should.== expected
    end
  end
  
  specify "serialize to params" do
    actual = @person.to_restful.serialize(:params)
  
    expected = 
      {
        :name => "Joe Bloggs",
        :current_location => "Under a tree",
        :created_at => @person.created_at,
        :wallet_attributes=>{:contents=>"an old photo, 5 euros in coins"},
        :pets_attributes => [ {:name => "mietze"} ]
      }

    actual.should.== expected
  end
  
  specify "serialize to an ar params hash" do    
    input = xml_fixture("pets")[:gracie]
    params = Restful.from_xml(input).serialize(:params)
    clone = Pet.create!(params)

    clone.name.should.== "Gracie"
    clone.species.should.== 123
    clone.person_id.should.== @person.id
  end
end