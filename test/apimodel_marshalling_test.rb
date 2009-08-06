require File.dirname(__FILE__) + '/test_helper.rb'

context "apimodel marshalling" do
  
  setup do 
    Person.restful_publish(:name, :current_location, :pets, :wallet)
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

  xspecify "should be able to handle relations that are nil/null" do
    @person.wallet = nil
    @person.save!
    @person.reload

    assert_nothing_raised do
      @person.to_restful
    end

  end

  specify "should be able to expand a :belongs_to relationship" do
    actual = @pet.to_restful(:owner).serialize(:xml)
    
    expected = <<EXPECTED
<?xml version="1.0" encoding="UTF-8"?>
<pet>
  <restful-url type="link">http://example.com:3000/pets/#{ @pet.id }</restful-url>
  <owner>
    <restful-url type="link">http://example.com:3000/people/#{ @person.id }</restful-url>
    <name>Joe Bloggs</name>
    <current-location>Under a tree</current-location>
    <wallet-restful-url type="link">http://example.com:3000/wallets/#{ @wallet.id }</wallet-restful-url>
    <pets type="array">
      <pet-restful-url type="link">http://example.com:3000/pets/#{ @pet.id }</pet-restful-url>
    </pets>
  </owner>
</pet>
EXPECTED

    xml_should_be_same(expected, actual)
  end
  
  xspecify "should return collapsed resources by default when :expansion => :collapsed is passed" do
    Person.restful_publish(:name, :wallet, :restful_options => { :expansion => :collapsed })
    actual = @person.to_restful.serialize(:xml)
  
    expected = <<EXPECTED
<?xml version="1.0" encoding="UTF-8"?>
<person>
  <restful-url type="link">http://example.com:3000/people/#{ @person.id }</restful-url>
  <name>Joe Bloggs</name>
  <wallet-restful-url type="link">http://example.com:3000/wallets/#{ @wallet.id }</wallet-restful-url>
</person>
EXPECTED

    xml_should_be_same(expected, actual)
  end

  xspecify "should be able to export content generated by methods that return strings" do
    actual = @person.to_restful(:location_sentence).serialize(:xml)

    expected = <<EXPECTED
<?xml version="1.0" encoding="UTF-8"?>
<person>
  <restful-url type="link">http://example.com:3000/people/#{ @person.id }</restful-url>
  <location-sentence>#{ @person.location_sentence }</location-sentence>
</person>
EXPECTED

    xml_should_be_same(expected, actual)
  end

  xspecify "should be able to export content generated by methods (not attributes) and compute the correct style" do
    actual = @person.to_restful(:oldest_pet).serialize(:xml)
    oldest = @person.oldest_pet
    
    expected = <<EXPECTED
<?xml version="1.0" encoding="UTF-8"?>
<person>
  <restful-url type="link">http://example.com:3000/people/#{ @person.id }</restful-url>
  <oldest-pet>
    <restful-url type="link">http://example.com:3000/pets/#{ oldest.id }</restful-url>
    <name>#{ oldest.name }</name>
  </oldest-pet>
</person>
EXPECTED

    xml_should_be_same(expected, actual)
  end
  
  xspecify "should be able to export content generated by methods (not attributes) while filtering with a nested configuration" do
    flunk
  end

  xspecify "should create element with nil='true' attribute if no relation is set" do 
    @person.wallet = nil
    @person.save

    actual = @person.to_restful(:wallet).serialize(:xml)
    expected = <<EXPECTED
<?xml version="1.0" encoding="UTF-8"?>
<person>
  <restful-url type="link">http://example.com:3000/people/#{ @person.id }</restful-url>
  <wallet nil="true"></wallet>
</person>
EXPECTED

    xml_should_be_same(expected, actual)
  end
  
  xspecify "serialize to xml, rails style" do
    actual = @person.to_restful.serialize(:xml)
    
    expected = <<EXPECTED
<?xml version="1.0" encoding="UTF-8"?>
<person>
  <restful-url type="link">http://example.com:3000/people/#{ @person.id }</restful-url>
  <name>Joe Bloggs</name>
  <current-location>Under a tree</current-location>
  <wallet>
    <restful-url type="link">http://example.com:3000/wallets/#{ @wallet.id }</restful-url>
    <contents>an old photo, 5 euros in coins</contents>
  </wallet>
  <pets type="array">
    <pet>
      <restful-url type="link">http://example.com:3000/pets/#{ @pet.id }</restful-url>
      <name>mietze</name>
    </pet>
  </pets>
</person>
EXPECTED
    xml_should_be_same(expected, actual)
  end
  
  xspecify "serialize to xml, atom style" do
    actual = @person.to_restful.serialize(:atom_like)
    
    expected = <<EXPECTED    
<?xml version="1.0" encoding="UTF-8"?>
<person xml:base="http://example.com:3000">
  <link rel="self" href="/people/#{ @person.id }"/>
  <name>Joe Bloggs</name>
  <current-location>Under a tree</current-location>
  <wallet>
    <link rel="self" href="/wallets/#{ @wallet.id }"/>
    <contents>an old photo, 5 euros in coins</contents>
  </wallet>
  <pets>
    <pet>
      <link rel="self" href="/pets/#{ @pet.id }"/>
      <name>mietze</name>
    </pet>
  </pets>
</person>
EXPECTED

    xml_should_be_same(expected, actual)
  end
  
  xspecify "deserialize from rails style xml" do
    restful = @person.to_restful
    expected = restful.serialize(:xml)
    serializer = Restful::Serializers::XMLSerializer.new
    resource = serializer.deserialize(expected)    
    actual = serializer.serialize(resource)
    
    xml_should_be_same(expected, actual)
  end
  
  xspecify "serialize to an ar params hash" do
    
    input = <<EXPECTED
<?xml version="1.0" encoding="UTF-8"?>
<pet>
  <person-restful-url type="link">http://example.com:3000/people/#{ @person.id }</person-restful-url>
  <species>123</species>
  <name>Gracie</name>
</pet>
EXPECTED

    params = Restful.from_xml(input).serialize(:params)
    clone = Pet.create!(params)
    
    clone.name.should.== "Gracie"
    clone.species.should.== 123
    clone.person_id.should.== @person.id
  end
  
  xspecify "deserialize from atom style xml" do
    restful = @pet.to_restful
    expected = restful.serialize(:atom_like)
    serializer = Restful::Serializers::AtomLikeSerializer.new
    resource = serializer.deserialize(expected)
    actual = serializer.serialize(resource)
    
    xml_should_be_same(expected, actual)
  end

  xspecify "serialize to params" do
    actual = @person.to_restful.serialize(:params)
    
    expected = 
      {
        :name => "Joe Bloggs",
        :current_location => "Under a tree",
        :wallet_attributes=>{:contents=>"an old photo, 5 euros in coins"},
        :pets_attributes => [ {:name => "mietze"} ]
      }

    actual.should.== expected
  end

  xspecify "deserialize from params" do
    restful = @person.to_restful
    expected = restful.serialize(:params)
    serializer = Restful::Serializers::ParamsSerializer.new
    resource = serializer.deserialize(expected)
    actual = Person.create(expected).to_restful.serialize(:params)
    
    actual.should.== expected
  end
end
