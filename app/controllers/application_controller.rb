class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  
  # AUTHENTICATION DISABLED FOR UI TESTING
  # All authentication is completely bypassed
  
  # Safe current_user access - returns a mock user
  def current_user
    @current_user ||= begin
      User.first || User.new(email: 'demo@example.com')
    rescue
      User.new(email: 'demo@example.com')
    end
  end
  
  def user_signed_in?
    true
  end
  
  helper_method :current_user, :user_signed_in?
end
