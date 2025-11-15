class RetirementsController < ApplicationController
  include Calculatable
  include ErrorHandler
  
  def index
    @retirements = current_user.retirements.order(created_at: :desc)
    @retirement = Retirement.new(user: current_user)
    
    # Get active scenario for summary cards (first scenario by default)
    active_retirement = @retirements.first
    
    if active_retirement
      projection_service = RetirementProjectionService.new(scenario: active_retirement)
      summary = projection_service.summary
      
      @current_progress = summary[:current_progress]
      @saved_amount = summary[:saved_amount]
      @goal_amount = summary[:goal_amount]
      @target_age = active_retirement.age_retirement || 65
      @annual_withdrawal = active_retirement.withdrawal_annual_pv || 0
      @years_to_goal = summary[:years_to_goal]
      @expected_return_rate = summary[:expected_return_rate]
      @projected_value = summary[:projected_value]
      @gap_to_goal = summary[:gap_to_goal]
      @monthly_contribution_needed = summary[:monthly_contribution_needed]
      @monthly_contribution_actual = summary[:monthly_contribution_actual]
    else
      @current_progress = 0
      @saved_amount = 0
      @years_to_goal = 0
      @goal_amount = 0
      @target_age = 65
      @expected_return_rate = 7.0
      @projected_value = 0
      @gap_to_goal = 0
      @monthly_contribution_needed = 0
      @monthly_contribution_actual = 0
      @annual_withdrawal = 0
    end
  end
  
  def set_active
    @retirement = current_user.retirements.find(params[:id])
    redirect_to retirements_path, notice: 'Scenario set as active. (Note: Currently using first scenario as active)'
  end
  
  def create
    @retirement = current_user.retirements.build(retirement_params)
    if @retirement.save
      redirect_to retirements_path, notice: 'Retirement scenario saved successfully.'
    else
      flash.now[:alert] = 'Error saving retirement scenario.'
      render :index
    end
  end
  
  def destroy
    @retirement = current_user.retirements.find(params[:id])
    @retirement.destroy
    redirect_to retirements_path, notice: 'Retirement scenario removed.'
  end
  
  def edit
    @retirement = current_user.retirements.find(params[:id])
  end
  
  def update
    @retirement = current_user.retirements.find(params[:id])
    if @retirement.update(retirement_params)
      redirect_to retirements_path, notice: 'Retirement scenario updated successfully.'
    else
      flash.now[:alert] = 'Error updating retirement scenario.'
      render :edit
    end
  end
  
  private
  
  def retirement_params
    params.require(:retirement).permit(:name, :age_start, :age_retirement, :age_end,
                                       :rate_inflation, :rate_contribution_growth,
                                       :rate_low, :rate_mid, :rate_high,
                                       :allocation_low_pre, :allocation_mid_pre, :allocation_high_pre,
                                       :allocation_low_post, :allocation_mid_post, :allocation_high_post,
                                       :contribution_annual_cents, :withdrawal_annual_pv_cents,
                                       :withdrawal_rate_fv, :notes)
  end
end

