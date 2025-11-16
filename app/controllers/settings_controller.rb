class SettingsController < ApplicationController
  def index
    @user_settings = current_user
    @data_files = current_user.data_files.order(created_at: :desc).limit(10)
    @referral_code = current_user.referral_code
    # Placeholder: Check if subscription is active (will be implemented with Stripe)
    @subscription_active = current_user.stripe_subscription_id.present?
  end
  
  def update
    if current_user.update(settings_params)
      redirect_to settings_path, notice: 'Settings updated successfully.'
    else
      flash.now[:alert] = 'Error updating settings.'
      render :index
    end
  end
  
  def update_account
    # Update email if provided
    if params[:user] && params[:user][:email].present?
      unless current_user.update(email: params[:user][:email])
        redirect_to settings_path, alert: 'Error updating email. ' + current_user.errors.full_messages.join(', ')
        return
      end
    end
    
    # Update password if provided
    if params[:new_password].present?
      if params[:current_password].blank?
        redirect_to settings_path, alert: 'Current password is required to change password.'
        return
      end
      
      unless current_user.authenticate(params[:current_password])
        redirect_to settings_path, alert: 'Current password is incorrect.'
        return
      end
      
      unless current_user.update(password: params[:new_password], password_confirmation: params[:password_confirmation])
        redirect_to settings_path, alert: 'Error updating password. ' + current_user.errors.full_messages.join(', ')
        return
      end
    end
    
    redirect_to settings_path, notice: 'Account updated successfully.'
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
    data = {
      user: {
        email: current_user.email,
        created_at: current_user.created_at,
        updated_at: current_user.updated_at
      },
      portfolios: current_user.portfolios.map(&:attributes),
      accounts: current_user.accounts.map(&:attributes),
      expenses: current_user.expenses.map(&:attributes),
      loans: current_user.loans.map(&:attributes),
      retirements: current_user.retirements.map(&:attributes),
      insurance_policies: current_user.insurance_policies.map(&:attributes),
      taxes: current_user.taxes.map(&:attributes),
      balances: current_user.accounts.map(&:balances).flatten.map(&:attributes),
      exported_at: Time.current.iso8601
    }
    
    json_data = JSON.pretty_generate(data)
    filename = "user_data_#{current_user.id}_#{Time.current.strftime('%Y%m%d_%H%M%S')}.json"
    
    # Also attach to user's data_files for historical record
    temp_file = Tempfile.new(['user_data', '.json'])
    temp_file.write(json_data)
    temp_file.rewind
    
    current_user.data_files.attach(
      io: temp_file,
      filename: filename,
      content_type: 'application/json'
    )
    
    temp_file.close
    temp_file.unlink
    
    # Send file for download
    send_data json_data,
      filename: filename,
      type: 'application/json',
      disposition: 'attachment'
  end
  
  def download_data_file
    attachment = current_user.data_files.find(params[:id])
    redirect_to rails_blob_path(attachment, disposition: 'attachment')
  rescue ActiveRecord::RecordNotFound
    redirect_to settings_path, alert: 'File not found.'
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
  
  def create_feedback
    @feedback = current_user.feedbacks.build(feedback_params)
    if @feedback.save
      redirect_to settings_path, notice: 'Thank you for your feedback!'
    else
      flash.now[:alert] = 'Error submitting feedback. ' + @feedback.errors.full_messages.join(', ')
      render :index
    end
  end
  
  private
  
  def settings_params
    params.require(:user).permit(:email, :timezone, :date_format)
  end
  
  def feedback_params
    params.require(:feedback).permit(:rating_net_promoter, :message)
  end
end

