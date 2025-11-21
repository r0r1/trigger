class ProviderConnection < ApplicationRecord
  belongs_to :user
  encrypts :access_token
  validates :provider, presence: true, uniqueness: { scope: :user_id }
  validates :access_token, presence: true
end
