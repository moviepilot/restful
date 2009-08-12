Gem::Specification.new do |s|
s.name = "restful"
s.version = "0.2"
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Daniel Bornkessel", "Rany Keddo"] 
  s.date = "2009-08-11"
  s.email = "M4SSIVE@m4ssive.com"
  s.extra_rdoc_files = %w{ README.markdown }
  s.files = %w{ init.rb lib lib/restful lib/restful/apimodel lib/restful/apimodel/attribute.rb lib/restful/apimodel/collection.rb lib/restful/apimodel/link.rb lib/restful/apimodel/resource.rb lib/restful/converters lib/restful/converters/active_record.rb lib/restful/rails lib/restful/rails/action_controller.rb lib/restful/rails/active_record lib/restful/rails/active_record/configuration.rb lib/restful/rails/active_record/metadata_tools.rb lib/restful/rails.rb lib/restful/serializers lib/restful/serializers/atom_like_serializer.rb lib/restful/serializers/base.rb lib/restful/serializers/params_serializer.rb lib/restful/serializers/xml_serializer.rb lib/restful.rb LICENSE.markdown rails rails/init.rb Rakefile README.markdown restful.gemspec script script/console test test/converters test/converters/active_record_converter_test.rb test/fixtures test/fixtures/models test/fixtures/models/person.rb test/fixtures/models/pet.rb test/fixtures/models/wallet.rb test/rails test/rails/active_record_metadata_test.rb test/rails/configuration_test.rb test/rails/restful_publish_test.rb test/serializers test/serializers/atom_serializer_test.rb test/serializers/json_serializer_test.rb test/serializers/params_serializer_test.rb test/serializers/xml_serializer_test.rb test/test_helper.rb TODO.markdown }
  s.has_rdoc = true
  s.rdoc_options = ["--line-numbers", "--inline-source"]
  s.homepage = "http://github.com/M4SSIVE/restful"
  s.require_paths = %w{ lib }
  s.requirements = %w{ brianmario-yajl-ruby }
  s.rubygems_version = "1.3.1"
  s.summary = "api niceness. 
end

