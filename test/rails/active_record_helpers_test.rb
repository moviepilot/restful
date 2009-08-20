require File.dirname(__FILE__) + '/../test_helper.rb'

context "active record helpers" do
  specify "restful path should return record base name as part of the path per default" do
    emu = Emu.create
    emu.restful_path.should.== "/pets/#{ emu.id }"
  end
end