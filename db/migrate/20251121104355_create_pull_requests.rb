class CreatePullRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :pull_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider
      t.string :external_id
      t.string :title
      t.string :url
      t.string :repo
      t.string :state
      t.string :author
      t.datetime :created_at_source
      t.datetime :updated_at_source
      t.datetime :merged_at

      t.timestamps
    end
    
    add_index :pull_requests, [:provider, :external_id], unique: true
    add_index :pull_requests, :state
  end
end
