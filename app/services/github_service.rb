require 'net/http'
require 'json'

class GithubService < RepositoryService
  BASE_URL = "https://api.github.com"

  def fetch_pull_requests
    connection = connection_for('github')
    return [] unless connection

    # For demonstration, fetching PRs from a hardcoded repo or user's repos
    # In a real app, we might want to let user select repos.
    # Here we'll fetch issues/PRs assigned to the user or created by them across repos.
    
    uri = URI("#{BASE_URL}/search/issues?q=is:pr+author:@me+state:open")
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{connection.access_token}"
    request['Accept'] = "application/vnd.github.v3+json"
    request['User-Agent'] = "PR-Collector-App"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      data['items'].map do |item|
        {
          provider: 'github',
          title: item['title'],
          url: item['html_url'],
          repo: item['repository_url'].split('/').last(2).join('/'),
          state: item['state'],
          created_at: item['created_at']
        }
      end
    else
      Rails.logger.error "GitHub API Error: #{response.body}"
      []
    end
  end
end
