class TicketCommit < ApplicationRecord
  belongs_to :ticket, inverse_of: :ticket_commits
  belongs_to :author, class_name: "User", optional: true, inverse_of: :ticket_commits

  normalizes :commit_sha, with: ->(value) { value.to_s.strip.downcase.presence }
  normalizes :pull_request_url, with: ->(value) { value.to_s.strip.presence }
  normalizes :repository_name, with: ->(value) { value.to_s.strip.presence }

  validates :commit_sha,
            length: { maximum: 64 },
            format: { with: /\A[0-9a-f]+\z/, message: "must contain only hexadecimal characters" },
            allow_blank: true
  validates :pull_request_url, length: { maximum: 500 }, allow_blank: true
  validates :repository_name, length: { maximum: 255 }, allow_blank: true
  validates :notes, length: { maximum: 2_000 }, allow_blank: true
  validates :commit_sha, uniqueness: { scope: :ticket_id }, allow_blank: true
  validate :commit_sha_or_pull_request_present

  scope :recent_first, -> { order(created_at: :desc) }

  def short_commit_sha
    commit_sha.to_s.first(8)
  end

  def label
    return "Commit #{short_commit_sha}" if commit_sha.present?
    return "PR link" if pull_request_url.present?

    "Implementation link"
  end

  private

  def commit_sha_or_pull_request_present
    return if commit_sha.present? || pull_request_url.present?

    errors.add(:base, "Commit SHA or pull request URL must be present")
  end
end
