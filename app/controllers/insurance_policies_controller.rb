class InsurancePoliciesController < ApplicationController
  include Calculatable
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
      flash.now[:alert] = 'Error saving policy.'
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
      flash.now[:alert] = 'Error updating policy.'
      render :edit
    end
  end
  
  def calculate
    policy_id = params[:policy_id]
    policy = current_user.insurance_policies.find_by(id: policy_id) if policy_id.present?
    
    if policy
      service = InsuranceAnalysisService.new(policy: policy, user: current_user)
      result = service.analyze
      render json: result
    else
      render json: { error: 'Policy not found' }, status: :not_found
    end
  rescue => e
    handle_calculation_error(e)
  end
  
  private
  
  def policy_params
    params.require(:insurance_policy).permit(:policy_type, :provider, :coverage_amount, :premium, :term_years, :status, :notes)
  end
end
