class AddConnectedToProviderConnections < ActiveRecord::Migration[8.0]
  def change
    add_column :provider_connections, :connected, :boolean, default: false, null: false
  end
end
