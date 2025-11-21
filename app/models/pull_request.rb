class PullRequest < ApplicationRecord
  belongs_to :user

  validates :provider, presence: true
  validates :external_id, presence: true, uniqueness: { scope: :provider }
  validates :title, presence: true
  validates :url, presence: true
  validates :state, presence: true

  scope :open, -> { where(state: 'open') }
  scope :closed, -> { where(state: 'closed') }
  scope :merged, -> { where.not(merged_at: nil) }
  scope :by_provider, ->(provider) { where(provider: provider) }
  scope :recent, -> { order(created_at_source: :desc) }
end
