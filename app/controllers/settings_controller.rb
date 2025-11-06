class SettingsController < ApplicationController
  def index
    @user_settings = current_user
  end
  
  def update
    if current_user.update(settings_params)
      redirect_to settings_path, notice: 'Settings updated successfully.'
    else
      flash.now[:alert] = 'Error updating settings.'
      render :index
    end
  end
  
  def update_password
    if current_user.authenticate(params[:current_password])
      if current_user.update(password: params[:new_password], password_confirmation: params[:password_confirmation])
        redirect_to settings_path, notice: 'Password updated successfully.'
      else
        redirect_to settings_path, alert: 'Error updating password. ' + current_user.errors.full_messages.join(', ')
      end
    else
      redirect_to settings_path, alert: 'Current password is incorrect.'
    end
  end
  
  def export_data
    attachment = UserDataService.export_user_data(current_user)
    if attachment
      redirect_to settings_path, notice: 'Data exported successfully.'
    else
      redirect_to settings_path, alert: 'Error exporting data.'
    end
  end
  
  def destroy_account
    if current_user.authenticate(params[:password])
      current_user.destroy
      cookies.delete(:session_token)
      redirect_to root_path, notice: 'Your account has been deleted.'
    else
      redirect_to settings_path, alert: 'Password is incorrect. Account not deleted.'
    end
  end
  
  private
  
  def settings_params
    params.require(:user).permit(:email, :currency, :timezone, :date_format)
  end
end

