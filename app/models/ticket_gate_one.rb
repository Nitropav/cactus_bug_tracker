class TicketGateOne < ApplicationRecord
  REQUIRED_FIELDS = %i[
    problem_description
    reproduction_steps
    expected_behavior
    actual_behavior
    environment_context
  ].freeze

  belongs_to :ticket, inverse_of: :gate_one

  validates :ticket_id, uniqueness: true

  before_save :sync_completed_at

  def complete?
    REQUIRED_FIELDS.all? { |field| public_send(field).present? }
  end

  private

  def sync_completed_at
    self.completed_at = complete? ? Time.current : nil
  end
end
