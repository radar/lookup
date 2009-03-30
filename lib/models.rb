class APILookup

  class LookupBase < ActiveRecord::Base
  end
  LookupBase.establish_connection(:adapter => "sqlite3", :database => File.join(File.dirname(__FILE__), "lookup.sqlite3"))

  class Api < LookupBase
    set_table_name "apis"
    has_many :constants
  end

  class Constant < LookupBase
    set_table_name "constants"
    belongs_to :api
    has_many :entries
  end

  class Entry < LookupBase
    set_table_name "entries"
    belongs_to :constant
  end

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
      t.integer :count, :default => 0
    end
    
    create_table :constants do |t|
      t.string :name, :url
      t.references :api
      t.integer :weighting, :default => 0
      t.integer :count, :default => 0
    end
  end
end

if !APILookup::Api.table_exists? && 
   !APILookup::Constant.table_exists? && 
   !APILookup::Entry.table_exists?
  SetupTables.up
  APILookup.update
end