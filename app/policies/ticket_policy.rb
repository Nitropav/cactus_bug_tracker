class TicketPolicy
  attr_reader :user, :ticket

  def initialize(user, ticket)
    @user = user
    @ticket = ticket
  end

  def index?
    user.present?
  end

  def show?
    user.present?
  end

  def create?
    user.present? && !reviewer?
  end

  def update?
    return false unless user.present?
    return true if admin?
    return true if developer?
    return true if reviewer?

    reporter_can_edit_ticket?
  end

  def destroy?
    return false unless user.present?
    return true if admin?

    reporter_can_delete_ticket?
  end

  def update_gate_one?
    return false unless user.present?
    return true if admin? || developer?

    reporter_can_edit_ticket?
  end

  def update_gate_two?
    return false unless user.present?

    admin? || developer?
  end

  def comment?
    user.present?
  end

  def permitted_attributes
    return %i[title summary status severity domain assigned_to_id external_reference] if admin? || developer?
    return %i[status] if reviewer?
    return %i[title summary status domain external_reference] if reporter_can_edit_ticket?

    []
  end

  def can_edit_attribute?(attribute_name)
    permitted_attributes.include?(attribute_name.to_sym)
  end

  def can_transition_to_status?(target_status)
    target_status = target_status.to_s

    return false unless update? || create?
    return true if admin?

    case
    when developer?
      %w[draft needs_info open in_progress needs_review resolved].include?(target_status)
    when reviewer?
      %w[needs_review resolved closed].include?(target_status)
    when reporter_can_edit_ticket?
      %w[draft needs_info].include?(target_status)
    else
      false
    end
  end

  def visible_status_options(from_status:)
    candidate_statuses = Ticket.statuses.keys.select do |status|
      can_transition_to_status?(status) && transition_allowed_from?(from_status, status)
    end

    candidate_statuses.presence || Array(from_status.presence || "draft")
  end

  private

  def admin?
    user&.role_admin?
  end

  def developer?
    user&.role_developer?
  end

  def reviewer?
    user&.role_reviewer?
  end

  def reporter?
    user&.role_reporter?
  end

  def owns_ticket?
    ticket.reported_by_id.present? && ticket.reported_by_id == user.id
  end

  def reporter_can_edit_ticket?
    reporter? && owns_ticket? && ticket.status.in?(%w[draft needs_info])
  end

  def reporter_can_delete_ticket?
    reporter? && owns_ticket? && ticket.status.in?(%w[draft needs_info])
  end

  def transition_allowed_from?(from_status, target_status)
    allowed_targets = TicketTransitionService::ALLOWED_TRANSITIONS.fetch(from_status.to_s.presence, [])
    allowed_targets.include?(target_status)
  end
end
