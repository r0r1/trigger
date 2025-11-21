require 'net/http'
require 'json'

class GitlabService < RepositoryService
  BASE_URL = "https://gitlab.com/api/v4"

  def fetch_pull_requests
    connection = connection_for('gitlab')
    return [] unless connection

    uri = URI("#{BASE_URL}/merge_requests?scope=created_by_me&state=opened")
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{connection.access_token}"
    
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
          repo: item['references']['full'],
          state: item['state'],
          created_at: item['created_at']
        }
      end
    else
      Rails.logger.error "GitLab API Error: #{response.body}"
      []
    end
  end
end
