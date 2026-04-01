class TrainingExample < ApplicationRecord
  STATUSES = {
    pending_review: 0,
    approved: 1,
    rejected: 2
  }.freeze

  attribute :status, :integer, default: STATUSES[:pending_review]

  enum :status, STATUSES, prefix: true

  belongs_to :ticket, inverse_of: :training_examples
  belongs_to :reviewed_by, class_name: "User", optional: true, inverse_of: :reviewed_training_examples

  validates :title, presence: true
  validates :status, presence: true

  scope :recent_first, -> { order(generated_at: :desc, created_at: :desc) }
  scope :pending_review_first, -> { order(Arel.sql("CASE WHEN status = 0 THEN 0 ELSE 1 END"), generated_at: :desc, created_at: :desc) }

  def display_status
    status.humanize
  end

  def source_ticket_status
    metadata.fetch("source_ticket_status", ticket.status)
  end

  def commit_shas
    Array(metadata["commit_shas"])
  end

  def pull_request_urls
    Array(metadata["pull_request_urls"])
  end

  def generated_timestamp
    generated_at || created_at
  end
end
