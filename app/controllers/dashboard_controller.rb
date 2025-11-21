class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @pull_requests = []
    @pull_requests.concat(GithubService.new(current_user).fetch_pull_requests)
    @pull_requests.concat(GitlabService.new(current_user).fetch_pull_requests)
    @pull_requests.concat(BitbucketService.new(current_user).fetch_pull_requests)
    
    # Sort by creation date descending
    @pull_requests.sort_by! { |pr| pr[:created_at] }.reverse!
  end
end
