class DashboardController < ApplicationController
  before_action :authenticate_user!


  def index
    @pull_requests = current_user.pull_requests.open.recent
  end

  def sync
    SyncPullRequestsJob.perform_later(current_user.id)
    flash[:notice] = "Pull request sync started in the background."
    
    redirect_to dashboard_index_path
  end
end
