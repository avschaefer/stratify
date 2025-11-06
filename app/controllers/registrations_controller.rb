class RegistrationsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]
  layout false

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    
    if @user.save
      begin
        session = @user.sessions.create!(
          ip_address: request.remote_ip,
          user_agent: request.user_agent
        )
        
        cookies.signed[:session_token] = {
          value: session.token,
          expires: session.expires_at,
          httponly: true,
          secure: Rails.env.production?
        }
        
        redirect_to dashboard_index_path, notice: 'Account created successfully.'
      rescue => e
        Rails.logger.error "Error creating session: #{e.message}"
        flash.now[:alert] = 'Account created but session failed. Please log in.'
        render :new, status: :unprocessable_entity
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end

