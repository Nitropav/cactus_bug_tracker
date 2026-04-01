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
    user.present?
  end

  def update?
    return false unless user.present?
    return true if admin?
    return true if developer?
    return true if support_agent?

    customer_can_edit_ticket?
  end

  def destroy?
    return false unless user.present?
    return true if admin?

    customer_can_delete_ticket?
  end

  def update_gate_one?
    return false unless user.present?
    return true if admin? || developer? || support_agent?

    customer_can_edit_ticket?
  end

  def update_gate_two?
    return false unless user.present?

    admin? || developer?
  end

  def comment?
    user.present?
  end

  def view_commits?
    user.present?
  end

  def manage_commits?
    return false unless user.present?

    admin? || developer?
  end

  def permitted_attributes
    return %i[title summary status severity domain assigned_to_id external_reference] if admin? || developer? || support_agent?
    return %i[title summary status domain external_reference] if customer_can_edit_ticket?

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
    when support_agent?
      %w[draft needs_info open in_progress needs_review closed].include?(target_status)
    when customer_can_edit_ticket?
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

  def support_agent?
    user&.role_support_agent?
  end

  def customer?
    user&.role_customer?
  end

  def owns_ticket?
    ticket.reported_by_id.present? && ticket.reported_by_id == user.id
  end

  def customer_can_edit_ticket?
    customer? && owns_ticket? && ticket.status.in?(%w[draft needs_info])
  end

  def customer_can_delete_ticket?
    customer? && owns_ticket? && ticket.status.in?(%w[draft needs_info])
  end

  def transition_allowed_from?(from_status, target_status)
    allowed_targets = TicketTransitionService::ALLOWED_TRANSITIONS.fetch(from_status.to_s.presence, [])
    allowed_targets.include?(target_status)
  end
end
