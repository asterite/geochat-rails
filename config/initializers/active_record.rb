module ActiveRecord
  class Base
    def self.attr_reader_as_symbol(*symbols)
      symbols.each do |symbol|
        define_method symbol do
          self.attributes[symbol.to_s].try(:to_sym)
        end
      end
    end

    def self.data_accessor(symbol, options = {})
      serialize :data

      define_method symbol do
        self.data ? self.data[symbol] : options[:default]
      end

      define_method "#{symbol}=" do |value|
        self.data ||= {}
        self.data[symbol] = value
      end
    end
  end
end
