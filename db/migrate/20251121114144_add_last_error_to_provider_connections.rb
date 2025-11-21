class AddLastErrorToProviderConnections < ActiveRecord::Migration[8.0]
  def change
    add_column :provider_connections, :last_error, :text
  end
end
