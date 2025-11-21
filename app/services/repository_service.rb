class RepositoryService
  attr_reader :user, :token

  def initialize(user)
    @user = user
  end

  def fetch_pull_requests
    raise NotImplementedError, "Subclasses must implement fetch_pull_requests"
  end

  protected

  def connection_for(provider)
    user.provider_connections.find_by(provider: provider)
  end
end
