class InsurancePoliciesController < ApplicationController
  def index
    @policies = current_user.insurance_policies.order(created_at: :desc)
    @policy = InsurancePolicy.new(user: current_user)
  end
  
  def create
    @policy = current_user.insurance_policies.build(policy_params)
    if @policy.save
      redirect_to insurance_policies_path, notice: 'Policy saved.'
    else
      flash.now[:alert] = 'Error saving policy.'
      render :index
    end
  end
  
  def destroy
    @policy = current_user.insurance_policies.find(params[:id])
    @policy.destroy
    redirect_to insurance_policies_path, notice: 'Policy removed.'
  end
  
  private
  
  def policy_params
    params.require(:insurance_policy).permit(:policy_type, :provider, :coverage_amount, :premium, :term_years, :status, :notes)
  end
end
