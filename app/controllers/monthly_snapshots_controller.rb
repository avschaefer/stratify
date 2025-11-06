class MonthlySnapshotsController < ApplicationController
  before_action :find_snapshotable, only: [:create]
  before_action :find_snapshot, only: [:update, :destroy]
  
  def create
    @snapshot = @snapshotable.monthly_snapshots.build(snapshot_params)
    
    # Ensure snapshotable belongs to current user
    unless snapshotable_belongs_to_user?
      redirect_back(fallback_location: root_path, alert: 'Access denied.')
      return
    end
    
    if @snapshot.save
      redirect_back(fallback_location: root_path, notice: 'Snapshot added successfully.')
    else
      redirect_back(fallback_location: root_path, alert: "Error adding snapshot: #{@snapshot.errors.full_messages.join(', ')}")
    end
  end
  
  def update
    unless snapshot_belongs_to_user?
      redirect_back(fallback_location: root_path, alert: 'Access denied.')
      return
    end
    
    if @snapshot.update(snapshot_params)
      redirect_back(fallback_location: root_path, notice: 'Snapshot updated successfully.')
    else
      redirect_back(fallback_location: root_path, alert: "Error updating snapshot: #{@snapshot.errors.full_messages.join(', ')}")
    end
  end
  
  def destroy
    unless snapshot_belongs_to_user?
      redirect_back(fallback_location: root_path, alert: 'Access denied.')
      return
    end
    
    @snapshot.destroy
    redirect_back(fallback_location: root_path, notice: 'Snapshot removed successfully.')
  end
  
  private
  
  def find_snapshotable
    if params[:savings_account_id]
      @snapshotable = current_user.savings_accounts.find(params[:savings_account_id])
    elsif params[:expense_id]
      @snapshotable = current_user.expenses.find(params[:expense_id])
    else
      redirect_back(fallback_location: root_path, alert: 'Invalid snapshotable.')
      return
    end
  end
  
  def find_snapshot
    @snapshot = MonthlySnapshot.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_back(fallback_location: root_path, alert: 'Snapshot not found.')
  end
  
  def snapshotable_belongs_to_user?
    return false unless @snapshotable
    @snapshotable.is_a?(SavingsAccount) ? @snapshotable.user_id == current_user.id : @snapshotable.user_id == current_user.id
  end
  
  def snapshot_belongs_to_user?
    return false unless @snapshot
    snapshotable = @snapshot.snapshotable
    return false unless snapshotable
    snapshotable.user_id == current_user.id
  end
  
  def snapshot_params
    params.require(:monthly_snapshot).permit(:balance, :recorded_at)
  end
end
