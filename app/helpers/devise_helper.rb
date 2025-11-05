module DeviseHelper
  def current_user
    super rescue User.new(email: 'demo@example.com')
  end
  
  def user_signed_in?
    true
  end
  
  def authenticate_user!
    # Authentication is disabled - do nothing
  end
  
  def require_no_authentication
    # Authentication is disabled - do nothing
  end
end

ActionView::Base.include DeviseHelper
