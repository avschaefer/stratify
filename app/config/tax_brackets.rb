# frozen_string_literal: true

# Tax bracket configuration by year
# Currently only supports 2024 federal tax brackets
class TaxBrackets
  BRACKETS_2024 = [
    { rate: 0.10, min: 0, max: 11_000 },
    { rate: 0.12, min: 11_001, max: 44_725 },
    { rate: 0.22, min: 44_726, max: 95_350 },
    { rate: 0.24, min: 95_351, max: 201_050 },
    { rate: 0.32, min: 201_051, max: 502_300 },
    { rate: 0.37, min: 502_301, max: Float::INFINITY }
  ].freeze
  
  def self.for_year(year)
    case year
    when 2024
      BRACKETS_2024
    else
      # Default to 2024 brackets if year not found
      BRACKETS_2024
    end
  end
  
  def self.available_years
    [2024]
  end
end

