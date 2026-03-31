class TicketTransitionService
  Result = Struct.new(:success?, :error, keyword_init: true)

  ALLOWED_TRANSITIONS = {
    nil => %w[draft needs_info],
    "draft" => %w[draft needs_info open],
    "needs_info" => %w[draft needs_info open],
    "open" => %w[needs_info open in_progress needs_review resolved],
    "in_progress" => %w[needs_info open in_progress needs_review resolved],
    "needs_review" => %w[needs_info in_progress needs_review resolved closed],
    "resolved" => %w[in_progress needs_review resolved closed],
    "closed" => %w[needs_info open closed]
  }.freeze

  def self.call(ticket:, actor:, from_status:, target_status:, policy:)
    new(ticket:, actor:, from_status:, target_status:, policy:).call
  end

  def initialize(ticket:, actor:, from_status:, target_status:, policy:)
    @ticket = ticket
    @actor = actor
    @from_status = from_status.to_s.presence
    @target_status = target_status.to_s
    @policy = policy
  end

  def call
    return failure("Unknown ticket status.") unless Ticket.statuses.key?(target_status)
    return success if from_status == target_status
    return failure("You do not have permission to change the ticket status to #{target_status.humanize.downcase}.") unless policy.can_transition_to_status?(target_status)
    return failure(invalid_transition_message) unless allowed_transition?
    return failure(gate_failure_message) unless ticket.can_transition_to?(target_status)

    success
  end

  private

  attr_reader :ticket, :actor, :from_status, :target_status, :policy

  def allowed_transition?
    allowed_targets = ALLOWED_TRANSITIONS.fetch(from_status, [])
    allowed_targets.include?(target_status)
  end

  def invalid_transition_message
    if from_status.present?
      "Ticket cannot move from #{from_status.humanize.downcase} to #{target_status.humanize.downcase}."
    else
      "New tickets must start in draft or needs info."
    end
  end

  def gate_failure_message
    case target_status
    when "open", "in_progress", "needs_review"
      "Gate 1 must be complete before the ticket can move into active work."
    when "resolved", "closed"
      "Both Gate 1 and Gate 2 must be complete before the ticket can be resolved or closed."
    else
      "That status change is not allowed yet."
    end
  end

  def success
    Result.new(success?: true, error: nil)
  end

  def failure(message)
    Result.new(success?: false, error: message)
  end
end
