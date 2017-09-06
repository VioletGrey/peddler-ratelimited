module Peddler
  class StructuredList
    CAPITAL_LETTERS = /[A-Z]/
    EXPECTED_ARGUMENTS = %w(InboundShipmentPlanRequestItems, InboundShipmentItems)

    alias :original_build :build

    def build(vals)
      if EXPECTED_ARGUMENTS.include? @keys.first
        @result = {}
        traverse(vals, @keys.join('.'))
        @result
      else
        original_build(vals)
      end
    end

    private 

    def traverse(vals, prefix)
      i = 1
      Array(vals).flatten.each do |el|
        if el.is_a?(Array) || el.is_a?(Hash)
          el.each_with_index do |(k, v), j|
            if v.is_a?(Array) || v.is_a?(Hash)
              traverse(v, "#{prefix}.#{i}.#{camelize(k)}")
            else
              @result["#{prefix}.#{i}.#{camelize(k)}"] = v
            end
          end
        else
          prefix += ".#{camelize(el)}"
          i -= 1
        end
        i += 1
      end
    end

    def camelize(sym)
      return sym.to_s if sym =~ CAPITAL_LETTERS

      sym
        .to_s
        .split('_')
        .map { |token| token == 'sku' ? 'SKU' : token.capitalize }
        .join
    end

  end
end
