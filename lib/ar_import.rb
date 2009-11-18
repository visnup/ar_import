require 'tempfile'
require 'fastercsv'

module Swivel
  module Acts
    module Import
      def self.included base
        base.extend ArImport::ClassMethods
      end

      module ArImport
        class Buffer
          attr_reader :warnings, :file

          def initialize record, buffer = []
            @file = Tempfile.new 'load_data_infile'
            @warnings = []
            @connection = record.connection
            @table_name = record.table_name

            buffer.each { |x| create x }
          end

          def create attributes
            @keys ||= attributes.keys
            values = attributes.values_at(*@keys).map {|x| @connection.quote x}
            @file.puts(values.join(","))
          end

          def flush
            @file.flush
            return unless File.size?(@file.path)

            @connection.execute "LOAD DATA LOCAL INFILE '#{@file.path}' INTO TABLE `#{@table_name}` FIELDS OPTIONALLY ENCLOSED BY '\\'' TERMINATED BY ',' (#{@keys.map{|x| "`#{x}`"}.join(',')})"

            # collect warnings
            warnings = @connection.execute 'SHOW WARNINGS'
            while w = warnings.fetch_row
              @warnings << w.last
            end

            @connection.clear_query_cache
          end

          def escape values
            values.map {|v| @connection.quote v}.join(',')
          end
        end

        module ClassMethods
          def import *args, &block
            if block_given?
              buffer = Buffer.new self
              yield buffer
              buffer.flush
            else
              buffer = Buffer.new self, args.flatten
              buffer.flush
            end

            buffer.warnings
          end
        end
      end
    end
  end
end
