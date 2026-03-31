class Ticket < ApplicationRecord
  STATUSES = {
    draft: 0,
    needs_info: 1,
    open: 2,
    in_progress: 3,
    needs_review: 4,
    resolved: 5,
    closed: 6
  }.freeze

  SEVERITIES = {
    low: 0,
    medium: 1,
    high: 2,
    critical: 3
  }.freeze

  DOMAINS = %w[bug_tracker product engineering infrastructure ai_pipeline integrations unknown].freeze

  attribute :status, :integer, default: STATUSES[:draft]
  attribute :severity, :integer, default: SEVERITIES[:medium]

  enum :status, STATUSES, prefix: true
  enum :severity, SEVERITIES, prefix: true

  belongs_to :reported_by, class_name: "User", inverse_of: :reported_tickets
  belongs_to :assigned_to, class_name: "User", optional: true, inverse_of: :assigned_tickets

  has_one :gate_one, class_name: "TicketGateOne", dependent: :destroy, inverse_of: :ticket
  has_one :gate_two, class_name: "TicketGateTwo", dependent: :destroy, inverse_of: :ticket

  validates :title, presence: true
  validates :domain, presence: true, inclusion: { in: DOMAINS }

  scope :active, -> { where.not(status: statuses[:closed]) }
  scope :recent_first, -> { order(created_at: :desc) }

  after_create :ensure_gate_records!

  def gate_one_complete?
    gate_one&.complete? || false
  end

  def gate_two_complete?
    gate_two&.complete? || false
  end

  def ready_to_open?
    gate_one_complete?
  end

  def ready_to_resolve?
    gate_two_complete?
  end

  def display_status
    status.humanize
  end

  def display_severity
    severity.humanize
  end

  def can_transition_to?(target_status)
    target_status = target_status.to_s

    case target_status
    when "open", "in_progress", "needs_review"
      gate_one_complete?
    when "resolved", "closed"
      gate_one_complete? && gate_two_complete?
    else
      true
    end
  end

  private

  def ensure_gate_records!
    create_gate_one! unless gate_one
    create_gate_two! unless gate_two
  end
end
