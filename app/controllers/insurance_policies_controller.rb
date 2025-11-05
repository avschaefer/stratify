class InsurancePoliciesController < ApplicationController
  def index
    @policies = []
    @policy = InsurancePolicy.new(user: current_user)
  end
  
  def create
    redirect_to insurance_policies_path, notice: 'Policy saved.'
  end
  
  def calculate
    render json: {
      total_cost: 0,
      monthly_premium: 0,
      annual_premium: 0
    }
  end
  
  def destroy
    redirect_to insurance_policies_path, notice: 'Policy removed.'
  end
end
