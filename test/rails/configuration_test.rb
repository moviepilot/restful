require File.dirname(__FILE__) + '/../test_helper.rb'

context "Configuration" do
  specify "should have an empty whitelist if only restful options are passed in" do
    config = Restful.cfg
    config.restful_options[:expansion] = :expanded
    config.whitelisted.should.empty
  end
  
  specify "should return fields without restful_options via whitelisted" do
    config = Restful.cfg([:one, :two])
    config.restful_options[:expansion] = :expanded
    config.whitelisted.should.not.include :restful_options
  end
  
  specify "should know if it has restful_options" do
    config = Restful.cfg([:one, :two])
    config.restful_options[:expansion] = :expanded
    config.restful_options.should.not.empty
  end
  
  specify "should be able to handle nested whitelist attributes" do
    config = Restful.cfg(:one, :two => [:a, :b])
    config.nested(:two).whitelisted.should.== [:a,:b]
  end
  
  specify "should know which attributes are published" do
    config = Restful.cfg(:one, :two => [:a, :b])
    config.published?(:two).should.== true
    config.published?(:one).should.== true
  end
  
  specify "should know if it is nested" do
    config = Restful.cfg(:one, :restful_options => {:nested => true})
    config.nested?.should.== true
  end
  
  specify "should preserve :include when :restful_options are present" do
    Person.restful_publish :pets
    p = Person.create
    p.pets.create
    
    restful = p.to_restful :include => :pets, :restful_options => {}
    restful.collections.size.should.== 1
  end
  
end