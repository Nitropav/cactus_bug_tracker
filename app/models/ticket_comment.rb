class TicketComment < ApplicationRecord
  belongs_to :ticket, inverse_of: :comments
  belongs_to :author, class_name: "User", inverse_of: :ticket_comments

  validates :body, presence: true

  scope :chronological, -> { order(created_at: :asc) }

  def preview
    body.to_s.tr("\n", " ").squish.truncate(120)
  end
end
