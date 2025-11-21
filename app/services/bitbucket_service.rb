require 'json'
require 'net/http'

class BitbucketService < RepositoryService
  BASE_URL = "https://api.bitbucket.org/2.0"

  def fetch_pull_requests
    connection = connection_for('bitbucket')
    return [] unless connection

    all_prs = []
    
    begin
      # Get workspace (required for Bitbucket)
      workspace = connection.workspace.presence || connection.username.presence || user.email.split('@').first
      username = connection.username.presence || user.email.split('@').first
      
      if workspace.blank? || username.blank?
        Rails.logger.warn "Bitbucket workspace or username not configured"
        return []
      end

      # Fetch all repositories in the workspace
      repos = fetch_repositories(workspace, username, connection.access_token)
      
      # For each repository, fetch open pull requests
      repos.each do |repo|
        repo_slug = repo['slug']
        prs = fetch_repo_pull_requests(workspace, repo_slug, username, connection.access_token)
        all_prs.concat(prs)
      end

      all_prs
    rescue StandardError => e
      Rails.logger.error "Bitbucket API Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      []
    end
  end

  private

  def fetch_repositories(workspace, username, token)
    uri = URI("#{BASE_URL}/repositories/#{workspace}?pagelen=100")
    request = Net::HTTP::Get.new(uri)
    request.basic_auth(username, token)
    
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      data['values'] || []
    else
      Rails.logger.error "Failed to fetch Bitbucket repositories: #{response.code} - #{response.body}"
      []
    end
  end

  def fetch_repo_pull_requests(workspace, repo_slug, username, token)
    uri = URI("#{BASE_URL}/repositories/#{workspace}/#{repo_slug}/pullrequests?state=OPEN&pagelen=50")
    request = Net::HTTP::Get.new(uri)
    request.basic_auth(username, token)
    
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      items = data['values'] || []
      
      items.map do |item|
        {
          provider: 'bitbucket',
          title: item['title'],
          url: item['links']&.dig('html', 'href'),
          repo: "#{workspace}/#{repo_slug}",
          state: item['state']&.downcase,
          author: item['author']&.dig('display_name') || item['author']&.dig('username'),
          created_at: item['created_on'],
          updated_at: item['updated_on'],
          merged_at: item['state'] == 'MERGED' ? item['updated_on'] : nil
        }
      end
    else
      Rails.logger.warn "Failed to fetch PRs for #{workspace}/#{repo_slug}: #{response.code}"
      []
    end
  end
end
