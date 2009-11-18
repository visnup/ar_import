require 'rubygems'
gem 'activerecord', '2.3.4'
require 'active_record'
require 'ar_import'
require 'ruby-debug'
require 'test/unit'

class MockModel
  def self.statements
    @@statements
  end

  def self.reset
    @@statements = []
  end

  def self.connection
    self
  end

  def self.quote name
    "`#{name}`"
  end

  def self.execute sql
    @@statements.push sql
    self
  end

  def self.fetch_row
  end

  def self.clear_query_cache
  end

  def self.table_name
    'mock_models'
  end

  include ::Swivel::Acts::Import
end

class ArImportTest < Test::Unit::TestCase
  def setup
    MockModel.reset
  end

  def test_responds_to_import
    assert MockModel.respond_to?(:import)
  end

  def test_imports
    MockModel.import do |buf|
      20.times do
        buf.create :name => 'fred', :job => 'something, here',
          :and => "'quoted' as saying!", :empty => nil
      end
    end

    assert_equal 2, MockModel.statements.size
    assert MockModel.statements[0].match(/LOAD DATA LOCAL INFILE '(\S+)' INTO TABLE `mock_models`/)
    assert_equal 'SHOW WARNINGS', MockModel.statements[1]

    assert_equal '', File.read($1)
  end
end
