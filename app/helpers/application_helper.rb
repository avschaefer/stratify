module ApplicationHelper
  # Company branding
  def company_name
    'Ryzon'
  end
  
  def company_tagline
    'Manage your money without the noise'
  end
  
  def company_description
    'A minimal toolkit to plan, track, and optimize your financial life—built for clarity, not clutter.'
  end

  def number_with_delimiter(number, options = {})
    options[:delimiter] ||= ','
    options[:separator] ||= '.'
    
    parts = number.to_s.split('.')
    parts[0] = parts[0].gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{options[:delimiter]}")
    parts.join(options[:separator])
  end
end
