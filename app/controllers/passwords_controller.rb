class PasswordsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create, :edit, :update]
  layout false

  def new
  end

  def create
    user = User.find_by(email: params[:email]&.downcase&.strip)
    
    if user
      # In a real app, you'd send a password reset email here
      # For now, we'll just redirect with a message
      redirect_to root_path, notice: 'If an account exists with that email, you will receive password reset instructions.'
    else
      # Don't reveal if email exists or not
      redirect_to root_path, notice: 'If an account exists with that email, you will receive password reset instructions.'
    end
  end

  def edit
    # In a real app, this would verify the reset token
    begin
      @user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to root_path, alert: 'Invalid password reset link.'
    end
  end

  def update
    begin
      @user = User.find(params[:id])
      
      if @user.update(password: params[:password], password_confirmation: params[:password_confirmation])
        redirect_to login_path, notice: 'Password updated successfully.'
      else
        render :edit, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to root_path, alert: 'Invalid password reset link.'
    end
  end
end

