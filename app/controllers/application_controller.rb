class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  
  before_action :authenticate_user!
  
  private

  def authenticate_user!
    unless user_signed_in?
      store_location
      redirect_to login_path, alert: 'Please sign in to continue.'
    end
  end

  def current_session
    return nil unless cookies.signed[:session_token]
    
    begin
      @current_session ||= Session.find_by(token: cookies.signed[:session_token])
    rescue => e
      Rails.logger.error "Error finding session: #{e.message}"
      nil
    end
  end

  def current_user
    return nil unless current_session.present?
    
    begin
      @current_user ||= current_session.user
    rescue => e
      Rails.logger.error "Error finding user: #{e.message}"
      nil
    end
  end

  def user_signed_in?
    return false unless current_session.present?
    return false if current_session.expired?
    return false unless current_user.present?
    true
  end

  def store_location
    session[:return_to] = request.fullpath if request.get?
  end

  def redirect_back_or_default(default = root_path)
    redirect_to(session.delete(:return_to) || default)
  end

  helper_method :current_user, :user_signed_in?, :current_session
end
