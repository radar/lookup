class Api < ActiveRecord::Base
  has_many :constants
end

class Constant < ActiveRecord::Base
  belongs_to :api
  has_many :entries
end

class Entry < ActiveRecord::Base
  belongs_to :constant
end

class SetupTables < ActiveRecord::Migration
  def self.up
    create_table :apis do |t|
      t.string :name, :url
    end
    
    create_table :entries do |t|
      t.string :name, :url
      t.references :constant
      t.integer :weighting, :default => 0
    end
    
    create_table :constants do |t|
      t.string :name, :url
      t.references :api
      t.integer :weighting, :default => 0
    end
  end
end

if !Api.table_exists? && !Constant.table_exists? && !Entry.table_exists?
  SetupTables.up
  Lookup.update
end