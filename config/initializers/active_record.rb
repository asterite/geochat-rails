module ActiveRecord
  class Base
    def self.attr_reader_as_symbol(*symbols)
      symbols.each do |symbol|
        define_method symbol do
          self.attributes[symbol.to_s].try(:to_sym)
        end
      end
    end
  end
end
