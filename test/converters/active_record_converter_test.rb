require File.dirname(__FILE__) + '/../test_helper.rb'

#
#  FIXME: remove xml serialzation here and test resource directly. 
#
context "active record converter" do
  setup do
    Person.restful_publish(:name, :wallet, :current_location, :pets => [:name, :species])
    Pet.restful_publish(:person_id, :name) # person_id gets converted to a link automagically.
    
    @person = Person.create(:name => "Joe Bloggs", :current_location => "Under a tree", :birthday => "1976-04-03")
    @wallet = @person.wallet = Wallet.create!(:contents => "something in the wallet")
    @pet = @person.pets.create(:name => "Mietze", :species => "cat")
  end
  
  teardown do
    reset_config
  end
  
  specify "should publish link and not resource when :oldest_pet_restful_url, where oldest_pet is a defined method" do
    Person.restful_publish(:oldest_pet_restful_url)
    @person.to_restful.links.size.should.== 1
    @person.to_restful.links.first.name.should.== "oldest-pet-restful-url"
  end
  
  specify "should publish link and not a nested resource with :wallet_restful_url" do
    Person.restful_publish(:wallet_restful_url)  
    @person.to_restful.links.size.should.== 1
    @person.to_restful.links.first.name.should.== "wallet-restful-url"
    @person.to_restful.links.first.value.should.== @wallet.restful_url
  end
  
  specify "should be able to force expansion. force expanded attributes can never be collapsed. " do
    Wallet.restful_publish(:contents)
    Person.restful_publish(:name, :wallet, :current_location, { :pets => [:name, :species], :restful_options => { :force_expand => :wallet } })
    Pet.restful_publish(:owner, :name)

    @pet.to_restful
  end
  
  specify "should return link attributes from a model" do
    @pet.to_restful.links.map { |node| node.name }.sort.should.equal [:person_id]
  end
  
  specify "should convert a NULL inner association such as person.wallet to a link with a null value" do
    @person.wallet = nil
    
    wallet = @person.to_restful(:restful_options => { :expansion => :collapsed }).links.select { |link| link.name == "wallet-restful-url" }.first
    wallet.should.not.== nil
    wallet.value.should.== nil
  end
  
  specify "should return plain attributes from a model" do
    @pet.to_restful.simple_attributes.map { |node| node.name }.should.equal [:name]
  end
  
  specify "should return collections attributes from a model" do
    restful = @person.to_restful
    restful.collections.map { |node| node.name }.sort.should.equal [:pets]
  end
  
  specify "should set correct type for date" do
    restful = @person.to_restful :birthday
    restful.simple_attributes.detect { |node| node.name == :birthday }.extended_type.should.== :date
  end
  
  specify "should be able to convert themselves to an apimodel containing all and only the attributes exposed by Model.publish_api" do    
    resource = @person.to_restful
    
    resource.simple_attributes.select { |node| node.name == :name }.should.not.blank
    resource.simple_attributes.select { |node| node.name == :biography }.should.blank

    mietze = @person.to_restful.collections .select { |node| node.name == :pets }.first.value.first
    mietze.simple_attributes.size.should.== 2
    mietze.simple_attributes.select { |node| node.name == :name }.should.not.blank
    mietze.simple_attributes.select { |node| node.name == :species }.should.not.blank
  end

  specify "should be able to convert themselves to an apimodel containing all and only the attributes exposed by Model.publish_api. this holds true if to_restful is called with some configuration options. " do    
    resource = @person.to_restful(:restful_options => { :nested => false })
    resource.simple_attributes.select { |node| node.name == :name }.should.not.blank
    resource.simple_attributes.select { |node| node.name == :biography }.should.blank

    mietze = resource.collections .select { |node| node.name == :pets }.first.value.first
    mietze.simple_attributes.size.should.== 2
    mietze.simple_attributes.select { |node| node.name == :name }.should.not.blank
    mietze.simple_attributes.select { |node| node.name == :species }.should.not.blank
  end
  
  specify "should be able to override to_restful published fields by passing them into the method" do
    api = @person.to_restful(:pets)

    api.simple_attributes.should.blank?
    api.collections.map { |node| node.name }.sort.should.equal [:pets]
  end
  
  specify "should be able to handle relations that are nil/null" do
    @person.wallet = nil
    @person.save!
    @person.reload

    assert_nothing_raised do
      @person.to_restful
    end
  end

  specify "should be able to expand a :belongs_to relationship" do
    xml_should_eql_fixture(@pet.to_restful_xml(:owner), "pets", :nameless_pet)
  end

  specify "should return collapsed resources by default when :expansion => :collapsed is passed" do
    Person.restful_publish(:name, :wallet, :restful_options => { :expansion => :collapsed })
    xml_should_eql_fixture(@person.to_restful_xml, "people", :joe_bloggs)
  end

  specify "should be able to export content generated by methods that return strings" do
    xml_should_eql_fixture(@person.to_restful_xml(:location_sentence), "people", :no_wallet)
  end

  specify "should be able to export content generated by methods (not attributes) and compute the correct style" do 
    xml_should_eql_fixture(@person.to_restful_xml(:oldest_pet), "people", :with_oldest_pet)
  end

  specify "should be able to export content generated by methods (not attributes) while filtering with a nested configuration" do
    xml_should_eql_fixture(@person.to_restful_xml(:oldest_pet => [:species]), "people", :with_oldest_pet_species)    
  end

  specify "should create element with nil='true' attribute if no relation is set" do 
    @person.wallet = nil
    @person.save

    xml_should_eql_fixture(@person.to_restful_xml(:wallet), "people", :joe_with_zwiebelleder)
  end

  specify "should include attributes when include parameter is passed to to_restful" do
    Person.restful_publish(:name)
    Pet.restful_publish(:name)
    
    @person = Person.create
    @pet = @person.pets.create(:name => "Mietze")

    @pet.to_restful(:include => :owner).values.map(&:name).should.include :owner
    Pet.restful_config.whitelisted.include?(:owner).should.equal false
  end
  
end

