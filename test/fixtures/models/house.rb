class House < ActiveRecord::Base
  has_many :people
  
  apiable
end