require 'json'

class GithubService < RepositoryService
  BASE_URL = "https://api.github.com"

  def fetch_pull_requests
    connection = connection_for('github')
    return [] unless connection

    # Use the official GitHub MCP server
    # We need to pass the token as an environment variable
    client = McpClient.new("npx -y @modelcontextprotocol/server-github", { "GITHUB_PERSONAL_ACCESS_TOKEN" => connection.access_token })

    all_prs = []
    
    # Fetch different types of PRs to get comprehensive coverage
    queries = [
      "is:pr author:@me state:open",           # PRs authored by user
      "is:pr assignee:@me state:open",         # PRs assigned to user
      "is:pr mentions:@me state:open",         # PRs mentioning user
      "is:pr review-requested:@me state:open", # PRs where user is requested to review
      "is:pr involves:@me state:open"          # PRs involving user in any way
    ]

    begin
      queries.each do |query|
        begin
          result = client.call_tool("search_issues", { q: query })

          # The result content is expected to be a JSON string in the first text block
          if result['content'] && result['content'].any?
            content_text = result['content'].first['text']
            
            # The MCP server might return the data as a JSON string
            items = JSON.parse(content_text)
            
            # Handle case where items might be wrapped or different structure
            # The GitHub API search returns { "total_count": ..., "items": [...] }
            # The MCP tool might return the list directly or the full response.
            # Let's assume it returns the list or we extract 'items' if present.
            
            raw_items = items.is_a?(Hash) && items['items'] ? items['items'] : items
            raw_items = [] unless raw_items.is_a?(Array)

            prs = raw_items.map do |item|
              {
                provider: 'github',
                title: item['title'],
                url: item['html_url'],
                repo: item['repository_url']&.split('/')&.last(2)&.join('/'),
                state: item['state'],
                author: item['user']&.dig('login'),
                created_at: item['created_at'],
                updated_at: item['updated_at'],
                merged_at: item['pull_request']&.dig('merged_at')
              }
            end
            
            all_prs.concat(prs)
          end
        rescue StandardError => e
          Rails.logger.warn "GitHub MCP query '#{query}' failed: #{e.message}"
        end
      end

      # Deduplicate by URL (same PR might appear in multiple queries)
      all_prs.uniq { |pr| pr[:url] }
    rescue StandardError => e
      Rails.logger.error "GitHub MCP Error: #{e.message}"
      []
    end
  end
end
