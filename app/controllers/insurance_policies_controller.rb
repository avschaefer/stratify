class InsurancePoliciesController < ApplicationController
  include ErrorHandler
  
  def index
    @policies = current_user.insurance_policies.order(created_at: :desc)
    @policy = InsurancePolicy.new(user: current_user)
  end
  
  def create
    @policy = current_user.insurance_policies.build(policy_params)
    if @policy.save
      redirect_to insurance_policies_path, notice: 'Policy saved.'
    else
      @policies = current_user.insurance_policies.order(created_at: :desc)
      flash.now[:alert] = 'Error saving policy. Please fill out all required fields.'
      render :index
    end
  end
  
  def destroy
    @policy = current_user.insurance_policies.find(params[:id])
    @policy.destroy
    redirect_to insurance_policies_path, notice: 'Policy removed.'
  end
  
  def edit
    @policy = current_user.insurance_policies.find(params[:id])
  end
  
  def update
    @policy = current_user.insurance_policies.find(params[:id])
    if @policy.update(policy_params)
      redirect_to insurance_policies_path, notice: 'Policy updated successfully.'
    else
      flash.now[:alert] = 'Error updating policy. Please fill out all required fields.'
      render :edit
    end
  end
  
  private
  
  def policy_params
    params.require(:insurance_policy).permit(:policy_type, :provider, :coverage_amount, :premium, :term_years, :status, :notes)
  end
end
