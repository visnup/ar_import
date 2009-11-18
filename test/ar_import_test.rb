require 'rubygems'
gem 'activerecord', '2.3.4'
require 'active_record'
require 'ar_import'
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

  def test_imports_every_200
    MockModel.import do |buf|
      202.times do
        buf.create :name => 'fred'
      end
    end

    assert_equal [
      'INSERT INTO `mock_models` (`name`) VALUES ' + (['(`fred`)']*201).join(','),
      'SHOW WARNINGS',
      'INSERT INTO `mock_models` (`name`) VALUES (`fred`)',
      'SHOW WARNINGS'
    ], MockModel.statements
  end
end
