module ApplicationHelper
  def number_with_delimiter(number, options = {})
    options[:delimiter] ||= ','
    options[:separator] ||= '.'
    
    parts = number.to_s.split('.')
    parts[0] = parts[0].gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{options[:delimiter]}")
    parts.join(options[:separator])
  end
end
