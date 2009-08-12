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
  
  teardown do
    reset_config
  end
  
  xspecify "serialize to json" do
    actual = @person.to_restful.serialize(:json)
  
    expected = 
      {
        :restful_url => "http://example.com:3000/people/#{ @person.id }",
        :name => "Joe Bloggs",
        :current_location => "Under a tree",
        :created_at => @person.created_at.xmlschema,
        :wallet=>{:contents=>"an old photo, 5 euros in coins"},
        :pets => [ {:name => "mietze"} ]
      }

    actual.should.==  Yajl::Encoder.encode(expected)
  end
end
