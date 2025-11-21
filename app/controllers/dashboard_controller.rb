class DashboardController < ApplicationController
  before_action :authenticate_user!


  def index
    @pull_requests = current_user.pull_requests.open.recent
  end

  def sync
    result = PullRequestSyncService.new(current_user).sync_all
    
    if result[:success]
      flash[:notice] = "Successfully synced #{result[:synced_count]} pull requests!"
    else
      flash[:alert] = "Sync failed: #{result[:error]}"
    end
    
    redirect_to dashboard_index_path
  end
end
