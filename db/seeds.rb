# Demo user for development, testing, and demos
demo_user = User.find_or_create_by!(email: 'demo@example.com') do |user|
  user.password = 'demo123'
  user.password_confirmation = 'demo123'
end

puts "Demo user created/found: #{demo_user.email}"
puts "Password: demo123"

# Create sample data for demo user (optional - uncomment if needed)
# demo_user.portfolios.create!(
#   asset_type: 'stock',
#   ticker: 'AAPL',
#   purchase_date: Date.today - 30.days,
#   purchase_price: 150.00,
#   quantity: 10,
#   status: 0
# )
#
# demo_user.loans.create!(
#   name: 'Mortgage',
#   principal: 250000.00,
#   interest_rate: 4.5,
#   term_years: 30,
#   status: 0
# )

puts "Seeding completed!"
