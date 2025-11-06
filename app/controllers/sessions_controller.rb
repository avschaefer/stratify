class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]
  layout false

  def new
    redirect_to dashboard_index_path if user_signed_in?
  end

  def create
    user = User.find_by(email: params[:email]&.downcase&.strip)
    
    if user&.authenticate(params[:password])
      begin
        session = user.sessions.create!(
          ip_address: request.remote_ip,
          user_agent: request.user_agent
        )
        
        cookies.signed[:session_token] = {
          value: session.token,
          expires: session.expires_at,
          httponly: true,
          secure: Rails.env.production?
        }
        
        redirect_back_or_default(dashboard_index_path)
      rescue => e
        Rails.logger.error "Error creating session: #{e.message}"
        flash.now[:alert] = 'An error occurred. Please try again.'
        render :new, status: :unprocessable_entity
      end
    else
      flash.now[:alert] = 'Invalid email or password.'
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    begin
      if current_session
        current_session.destroy
      end
    rescue => e
      Rails.logger.error "Error destroying session: #{e.message}"
    ensure
      cookies.delete(:session_token)
      redirect_to root_path, notice: 'Signed out successfully.'
    end
  end
end

