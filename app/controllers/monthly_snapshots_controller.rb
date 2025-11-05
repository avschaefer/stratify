class MonthlySnapshotsController < ApplicationController
  def create
    redirect_back(fallback_location: root_path, notice: 'Snapshot added.')
  end
  
  def update
    redirect_back(fallback_location: root_path, notice: 'Snapshot updated.')
  end
  
  def destroy
    redirect_back(fallback_location: root_path, notice: 'Snapshot removed.')
  end
end
