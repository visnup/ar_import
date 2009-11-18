require 'ar_import'
ActiveRecord::Base.send :include, Swivel::Acts::Import
