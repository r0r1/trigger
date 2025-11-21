require 'net/http'
require 'json'

class GitlabService < RepositoryService
  BASE_URL = "https://gitlab.com/api/v4"

  def fetch_pull_requests
    connection = connection_for('gitlab')
    return [] unless connection

    all_mrs = []

    # Fetch different scopes of merge requests
    scopes = [
      'created_by_me',    # MRs created by user
      'assigned_to_me',   # MRs assigned to user
      'review_requested'  # MRs where user is requested as reviewer (GitLab 13.8+)
    ]

    begin
      scopes.each do |scope|
        begin
          mrs = fetch_merge_requests_by_scope(scope, connection.access_token)
          all_mrs.concat(mrs)
        rescue StandardError => e
          Rails.logger.warn "GitLab scope '#{scope}' failed: #{e.message}"
        end
      end

      # Deduplicate by URL
      all_mrs.uniq { |mr| mr[:url] }
    rescue StandardError => e
      Rails.logger.error "GitLab API Error: #{e.message}"
      []
    end
  end

  private

  def fetch_merge_requests_by_scope(scope, token)
    uri = URI("#{BASE_URL}/merge_requests?scope=#{scope}&state=opened&per_page=100")
    request = Net::HTTP::Get.new(uri)
    # GitLab uses PRIVATE-TOKEN header for Personal Access Tokens
    request['PRIVATE-TOKEN'] = token
    
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      data.map do |item|
        {
          provider: 'gitlab',
          title: item['title'],
          url: item['web_url'],
          repo: item['references']&.dig('full') || "#{item['project_id']}",
          state: item['state'],
          author: item['author']&.dig('username'),
          created_at: item['created_at'],
          updated_at: item['updated_at'],
          merged_at: item['merged_at']
        }
      end
    else
      Rails.logger.error "GitLab API Error (#{scope}): #{response.code} - #{response.body}"
      []
    end
  end
end
