module Swivel
  module Acts
    module Import
      def self.included base
        base.extend ArImport::ClassMethods
      end

      module ArImport
        class Buffer
          attr_reader :warnings

          def initialize record, buffer = [], limit = 200
            @buffer = buffer
            @limit = limit
            @warnings = []
            @connection = record.connection
            @table_name = record.table_name
          end

          def create attributes
            @buffer << attributes
            flush if @buffer.length > @limit
          end

          def flush
            return if @buffer.empty?

            first = @buffer.shift
            keys = first.keys
            StringIO.open do |sql|
              sql.write "INSERT INTO `#{@table_name}` (#{keys.map { |k| "`#{k}`" }.join(',')}) VALUES (#{escape(first.values_at(*keys))})"

              @buffer.each do |r|
                sql.write ",(#{escape(r.values_at(*keys))})"
              end
              @connection.execute sql.string
            end

            # collect warnings
            warnings = @connection.execute 'SHOW WARNINGS'
            while w = warnings.fetch_row
              @warnings << w.last
            end

            @connection.clear_query_cache
            @buffer = []
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
