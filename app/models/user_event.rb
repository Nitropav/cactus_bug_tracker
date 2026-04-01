class UserEvent < ApplicationRecord
  EVENT_TYPES = {
    "user_created" => "Created",
    "user_updated" => "Updated",
    "user_password_reset" => "Password",
    "user_deactivated" => "Disabled",
    "user_reactivated" => "Reactivated"
  }.freeze

  belongs_to :user, inverse_of: :user_events
  belongs_to :actor, class_name: "User", optional: true, inverse_of: :acted_user_events

  validates :event_type, presence: true
  validates :message, presence: true

  scope :recent_first, -> { order(created_at: :desc) }

  def badge_label
    EVENT_TYPES.fetch(event_type, event_type.humanize)
  end

  def badge_modifier
    case event_type
    when "user_created", "user_reactivated" then "complete"
    when "user_password_reset", "user_updated" then "workflow"
    when "user_deactivated" then "pending"
    else
      "workflow"
    end
  end
end
