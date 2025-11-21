class SettingsController < ApplicationController
  before_action :authenticate_user!

  def index
    @connections = current_user.provider_connections.index_by(&:provider)
    @providers = ['github', 'gitlab', 'bitbucket']
  end

  def update
    provider = params[:provider]
    token = params[:access_token]

    if token.present?
      connection = current_user.provider_connections.find_or_initialize_by(provider: provider)
      connection.access_token = token
      if connection.save
        flash[:notice] = "#{provider.titleize} connection updated."
      else
        flash[:alert] = "Failed to update #{provider.titleize} connection."
      end
    else
      # If token is empty, maybe we want to delete the connection?
      # For now, let's just ignore or show error.
      current_user.provider_connections.where(provider: provider).destroy_all
      flash[:notice] = "#{provider.titleize} connection removed."
    end

    redirect_to settings_path
  end
end
