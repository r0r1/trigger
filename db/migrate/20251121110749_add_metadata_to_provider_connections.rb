class AddMetadataToProviderConnections < ActiveRecord::Migration[8.0]
  def change
    add_column :provider_connections, :workspace, :string
    add_column :provider_connections, :username, :string
  end
end
