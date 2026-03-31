class TicketGateTwo < ApplicationRecord
  REQUIRED_FIELDS = %i[
    root_cause
    fix_summary
    verification_steps
  ].freeze

  belongs_to :ticket, inverse_of: :gate_two

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
