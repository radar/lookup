class Entry < ActiveRecord::Base
  belongs_to :constant
  
  def to_s
    "#{with_constant}: #{url}"
  end
  
  def with_constant
    "#{constant.name}##{name}"
  end
  
  
end
