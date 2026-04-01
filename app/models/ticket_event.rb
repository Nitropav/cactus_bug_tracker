class TicketEvent < ApplicationRecord
  EVENT_FILTERS = {
    "all" => nil,
    "workflow" => %w[ticket_created ticket_updated status_changed],
    "gates" => %w[gate_one_updated gate_two_updated],
    "implementation" => %w[commit_linked commit_unlinked],
    "discussion" => %w[comment_created]
  }.freeze

  belongs_to :ticket, inverse_of: :events
  belongs_to :actor, class_name: "User", optional: true, inverse_of: :ticket_events

  validates :event_type, presence: true
  validates :message, presence: true

  scope :chronological, -> { order(created_at: :asc) }
  scope :recent_first, -> { order(created_at: :desc) }
  scope :filtered_by, lambda { |filter_key|
    event_types = EVENT_FILTERS.fetch(filter_key.to_s, nil)
    event_types.present? ? where(event_type: event_types) : all
  }

  def self.filter_options
    EVENT_FILTERS.keys
  end

  def filter_group
    self.class::EVENT_FILTERS.find { |_key, values| values&.include?(event_type) }&.first || "all"
  end

  def badge_label
    case event_type
    when "ticket_created" then "Created"
    when "ticket_updated" then "Updated"
    when "status_changed" then "Status"
    when "gate_one_updated" then "Gate 1"
    when "gate_two_updated" then "Gate 2"
    when "commit_linked" then "Commit"
    when "commit_unlinked" then "Commit"
    when "comment_created" then "Comment"
    else
      event_type.humanize
    end
  end
end
