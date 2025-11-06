# frozen_string_literal: true

# Custom exception for financial calculation errors
class FinancialCalculationError < StandardError
  attr_reader :original_error, :context
  
  def initialize(message = 'Financial calculation error', original_error: nil, context: {})
    super(message)
    @original_error = original_error
    @context = context
  end
end

# Custom exception for invalid input errors
class InvalidInputError < StandardError
  attr_reader :field, :value
  
  def initialize(message = 'Invalid input', field: nil, value: nil)
    super(message)
    @field = field
    @value = value
  end
end

