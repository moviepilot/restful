Refactor this shice. Seriously, this has devolved into some nasty-ass code. 
  
* the metamodel is kind of weird. make a better metamodel - how about just using activemodel?
* remove requirement to call apiable in model classes; replace with restful_publish with no args (or with args.)
* move configuration object out of rails folder - this is general stuff. 
* remove xml serialization here and test resource directly (in active_record_converter_test)
* get rid of to_a warning
* convert underscores to dashes (or not) in serializers instead of converter
* implement xml serialization of hashes
* write tests to show that [Person.new].to_restful_xml(:include => :wallet) fails to preserve Person whitelist. 