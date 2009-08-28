17. Aug 2009 - 0.2.6

* added :include option in to_restful.

18. Aug 2009 - 0.2.7

* fixed issue where configurations where overwriting each other. 
* added hash#to_restful

19. Aug 2009 - 0.2.12

* added ability to publish :wallet-restful-url (explicitly collapsed)

20. Aug 2009 
  
  - 0.2.13

    * hash serializer no longer dereferences ids
    
  - 0.2.14
    
    * arrays names now use base_class of content models
    * restful_path defaults to using base_class in path
    * if array responds to name, use this as collection name

  - 0.2.15

    * :includes like active record to_xml to_json

21. Aug 2009

* refactored HashSerializer to be much clearer

26. Aug 2009

* fixed issue with link collapsing

28. Aug 2009

* fixed cascading of :includes