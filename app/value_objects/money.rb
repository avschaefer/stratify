# frozen_string_literal: true

# Value object representing money with currency
# Immutable object for financial calculations
class Money
  include Comparable
  
  attr_reader :amount, :currency
  
  CURRENCIES = %w[USD EUR GBP CAD AUD JPY CHF].freeze
  
  def initialize(amount:, currency: 'USD')
    @amount = BigDecimal(amount.to_s)
    @currency = currency.to_s.upcase
    
    validate!
  end
  
  def +(other)
    validate_same_currency!(other)
    Money.new(amount: amount + other.amount, currency: currency)
  end
  
  def -(other)
    validate_same_currency!(other)
    Money.new(amount: amount - other.amount, currency: currency)
  end
  
  def *(multiplier)
    Money.new(amount: amount * multiplier, currency: currency)
  end
  
  def /(divisor)
    raise ArgumentError, 'Division by zero' if divisor.zero?
    Money.new(amount: amount / divisor, currency: currency)
  end
  
  def zero?
    amount.zero?
  end
  
  def negative?
    amount.negative?
  end
  
  def positive?
    amount.positive?
  end
  
  def round(precision = 2)
    Money.new(amount: amount.round(precision), currency: currency)
  end
  
  def to_f
    amount.to_f
  end
  
  def to_s
    formatted
  end
  
  def formatted(symbol: true)
    if symbol
      case currency
      when 'USD', 'CAD', 'AUD'
        "#{currency_symbol}#{number_with_delimiter(amount.to_f)}"
      when 'EUR'
        "#{number_with_delimiter(amount.to_f)}#{currency_symbol}"
      when 'GBP'
        "#{currency_symbol}#{number_with_delimiter(amount.to_f)}"
      when 'JPY'
        "#{currency_symbol}#{number_with_delimiter(amount.to_f, delimiter: ',')}"
      when 'CHF'
        "#{number_with_delimiter(amount.to_f)} #{currency_symbol}"
      else
        "#{number_with_delimiter(amount.to_f)} #{currency}"
      end
    else
      number_with_delimiter(amount.to_f)
    end
  end
  
  def <=>(other)
    return nil unless other.is_a?(Money)
    validate_same_currency!(other)
    amount <=> other.amount
  end
  
  def ==(other)
    return false unless other.is_a?(Money)
    amount == other.amount && currency == other.currency
  end
  
  def hash
    [amount, currency].hash
  end
  
  def eql?(other)
    self == other
  end
  
  private
  
  def validate!
    raise ArgumentError, "Invalid currency: #{currency}" unless CURRENCIES.include?(currency)
  end
  
  def validate_same_currency!(other)
    raise ArgumentError, "Currency mismatch: #{currency} != #{other.currency}" unless currency == other.currency
  end
  
  def currency_symbol
    case currency
    when 'USD', 'CAD', 'AUD'
      '$'
    when 'EUR'
      '€'
    when 'GBP'
      '£'
    when 'JPY'
      '¥'
    when 'CHF'
      'CHF'
    else
      currency
    end
  end
  
  def number_with_delimiter(number, delimiter: ',')
    parts = number.to_s.split('.')
    parts[0].gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}") + (parts[1] ? ".#{parts[1]}" : '')
  end
end

