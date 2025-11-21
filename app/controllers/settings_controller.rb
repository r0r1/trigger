class SettingsController < ApplicationController
  before_action :authenticate_user!

  def index
    @connections = current_user.provider_connections.reload.index_by(&:provider)
    @providers = ['github', 'gitlab', 'bitbucket']
  end

  def update
    provider = params[:provider]
    token = params[:access_token]

    if token.present?
      connection = current_user.provider_connections.find_or_initialize_by(provider: provider)
      connection.access_token = token
      connection.connected = false  # Reset to false until tested
      
      # Handle Bitbucket-specific fields
      if provider == 'bitbucket'
        connection.username = params[:username] if params[:username].present?
        connection.workspace = params[:workspace] if params[:workspace].present?
      end
      
      if connection.save
        flash[:notice] = "#{provider.titleize} credentials saved. Please test the connection."
      else
        flash[:alert] = "Failed to update #{provider.titleize} connection."
      end
    else
      # If token is empty, maybe we want to delete the connection?
      # For now, let's just ignore or show error.
      current_user.provider_connections.where(provider: provider).destroy_all
      flash[:notice] = "#{provider.titleize} connection removed."
    end

    redirect_to settings_path, turbo: false
  end

  def test_connection
    provider = params[:provider]
    connection = current_user.provider_connections.find_by(provider: provider)

    if connection.nil?
      render json: { success: false, message: "No connection found. Please save your credentials first." }, status: :not_found
      return
    end

    begin
      service = case provider
                when 'github'
                  GithubService.new(current_user)
                when 'gitlab'
                  GitlabService.new(current_user)
                when 'bitbucket'
                  BitbucketService.new(current_user)
                else
                  nil
                end

      if service.nil?
        render json: { success: false, message: "Unknown provider" }, status: :bad_request
        return
      end

      # Try to fetch PRs as a connection test
      result = service.fetch_pull_requests
      
      # Update connected status to true on success and clear error
      connection.update(connected: true, last_error: nil)
      
      # If we get here without error, connection is successful
      render json: { 
        success: true, 
        message: "Connection successful! Found #{result.length} open PR(s).",
        count: result.length
      }
    rescue StandardError => e
      Rails.logger.error "Connection test failed for #{provider}: #{e.message}"
      
      # Store the error message
      error_message = e.message
      
      # Update connected status to false and store error
      connection.update(connected: false, last_error: error_message)
      
      render json: { 
        success: false, 
        message: "Connection failed: #{error_message}",
        error: error_message
      }, status: :unprocessable_entity
    end
  end
end
