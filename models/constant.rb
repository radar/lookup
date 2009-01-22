class Constant < ActiveRecord::Base
  has_many :entries
  
  def to_s
    "#{name}: #{url}"
  end
end
