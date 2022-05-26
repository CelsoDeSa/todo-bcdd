# frozen_string_literal: true

require 'kind'

module Kind
  class Value
    require_relative 'kind_value/validation'

    module Strategy
      def generate_default_for_nil_inputs=(bool)
        @generate_default_for_nil_inputs = bool
      end

      def generate_default_for_nil_inputs
        @generate_default_for_nil_inputs
      end

      def generate_default_value
        nil
      end

      def normalize(input)
        input
      end

      private

        def value_class
          @value_class
        end
    end

    def self.value_object(with: nil)
      mod = ::Module.new
      mod.extend(::Kind::Value::Strategy)
      mod.generate_default_for_nil_inputs = true
      mod.instance_variable_set(:@value_class, self)

      if with == :validation
        include(Validation)

        extend(Validation::Macros)

        mod.extend(Validation::Strategy)
      end

      yield(mod)

      const_set(:Strategy, mod)
    end

    def self.strategy_to
      @strategy_to ||= const_get(:Strategy, false)
    end

    def self.value(input)
      input.is_a?(self) ? input.value : strategy_to.normalize(input)
    end

    def self.new(input = ::Kind::Undefined)
      return input if input.is_a?(self.class)

      value =
        if ::Kind::Undefined == input || (input.nil? && strategy_to.generate_default_for_nil_inputs)
          strategy_to.generate_default_value
        else
          input
        end

      instance = allocate
      instance.send(:initialize, value)
      instance
    end

    def self.to_proc
      @to_proc ||= ->(value = ::Kind::Undefined) { new(value) }
    end

    attr_reader :value

    def initialize(value)
      @value = self.class.strategy_to.normalize(value)

      call_after_the_initialization
    end

    def ==(other)
      other.is_a?(self.class) && value == other.value
    end

    def blank?
      return value.blank? if value.respond_to?(:blank?)

      raise NotImplementedError
    end

    def present?
      !blank?
    end

    private

      def call_after_the_initialization
      end
  end
end
