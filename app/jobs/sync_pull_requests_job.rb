class SyncPullRequestsJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    result = PullRequestSyncService.new(user).sync_all
    
    if result[:success]
      Rails.logger.info "SyncPullRequestsJob: Successfully synced #{result[:synced_count]} pull requests for user #{user.id}"
    else
      Rails.logger.error "SyncPullRequestsJob: Failed to sync pull requests for user #{user.id}: #{result[:error]}"
    end
  end
end
