class PullRequestSyncService
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def sync_all
    results = {
      github: sync_github,
      gitlab: sync_gitlab,
      bitbucket: sync_bitbucket
    }

    {
      success: true,
      synced_count: results.values.sum,
      details: results
    }
  rescue StandardError => e
    Rails.logger.error "PR Sync Error: #{e.message}"
    {
      success: false,
      error: e.message
    }
  end

  private

  def sync_github
    prs = GithubService.new(user).fetch_pull_requests
    sync_prs(prs, 'github')
  end

  def sync_gitlab
    prs = GitlabService.new(user).fetch_pull_requests
    sync_prs(prs, 'gitlab')
  end

  def sync_bitbucket
    prs = BitbucketService.new(user).fetch_pull_requests
    sync_prs(prs, 'bitbucket')
  end

  def sync_prs(prs, provider)
    count = 0
    prs.each do |pr_data|
      # Extract external_id from URL or use a combination
      external_id = extract_external_id(pr_data[:url], provider)
      
      pr = user.pull_requests.find_or_initialize_by(
        provider: provider,
        external_id: external_id
      )

      pr.assign_attributes(
        title: pr_data[:title],
        url: pr_data[:url],
        repo: pr_data[:repo],
        state: pr_data[:state],
        author: pr_data[:author] || user.email,
        created_at_source: pr_data[:created_at],
        updated_at_source: pr_data[:updated_at] || pr_data[:created_at],
        merged_at: pr_data[:merged_at]
      )

      if pr.save
        count += 1
      else
        Rails.logger.warn "Failed to save PR: #{pr.errors.full_messages.join(', ')}"
      end
    end
    count
  end

  def extract_external_id(url, provider)
    case provider
    when 'github'
      # GitHub PR URL: https://github.com/owner/repo/pull/123
      url.match(%r{/pull/(\d+)})&.[](1) || url
    when 'gitlab'
      # GitLab MR URL: https://gitlab.com/owner/repo/-/merge_requests/123
      url.match(%r{/merge_requests/(\d+)})&.[](1) || url
    when 'bitbucket'
      # Bitbucket PR URL: https://bitbucket.org/owner/repo/pull-requests/123
      url.match(%r{/pull-requests/(\d+)})&.[](1) || url
    else
      url
    end
  end
end
