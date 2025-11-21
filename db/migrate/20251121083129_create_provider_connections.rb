class CreateProviderConnections < ActiveRecord::Migration[8.0]
  def change
    create_table :provider_connections do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider
      t.text :access_token

      t.timestamps
    end
  end
end
