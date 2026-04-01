class UserEventLogger
  def self.log!(user:, actor:, event_type:, message:, metadata: {})
    user.user_events.create!(
      actor: actor,
      event_type: event_type,
      message: message,
      metadata: metadata
    )
  end

  def self.log_user_created!(user:, actor:)
    log!(
      user: user,
      actor: actor,
      event_type: "user_created",
      message: "User account created with role #{user.display_role.downcase}.",
      metadata: { role: user.role, active: user.active? }
    )
  end

  def self.log_user_updated!(user:, actor:, changes:)
    tracked = changes.slice("name", "email", "role", "active")
    return if tracked.empty?

    changed_labels = tracked.keys.map { |key| key.humanize(capitalize: false) }
    log!(
      user: user,
      actor: actor,
      event_type: "user_updated",
      message: "Updated #{changed_labels.join(', ')}.",
      metadata: tracked
    )
  end

  def self.log_password_reset!(user:, actor:)
    log!(
      user: user,
      actor: actor,
      event_type: "user_password_reset",
      message: "Password reset by admin.",
      metadata: {}
    )
  end

  def self.log_deactivated!(user:, actor:)
    log!(
      user: user,
      actor: actor,
      event_type: "user_deactivated",
      message: "User account deactivated.",
      metadata: { active: false, deactivated_at: user.deactivated_at }
    )
  end

  def self.log_reactivated!(user:, actor:)
    log!(
      user: user,
      actor: actor,
      event_type: "user_reactivated",
      message: "User account reactivated.",
      metadata: { active: true }
    )
  end
end
