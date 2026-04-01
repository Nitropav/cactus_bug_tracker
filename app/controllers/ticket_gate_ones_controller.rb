class TicketGateOnesController < ApplicationController
  before_action :set_ticket

  def update
    return deny_access! unless ticket_policy(@ticket).update_gate_one?

    if @ticket.gate_one.update(gate_one_params)
      TicketEventLogger.log_gate_updated!(
        ticket: @ticket,
        actor: current_user,
        gate_name: "Gate 1",
        complete: @ticket.gate_one.complete?,
        changed_fields: @ticket.gate_one.saved_changes.keys - %w[updated_at completed_at]
      )
      sync_training_example_for(@ticket)
      redirect_to @ticket, notice: gate_notice(@ticket.gate_one.complete?, "Gate 1")
    else
      redirect_to @ticket, alert: "Gate 1 could not be updated."
    end
  end

  private

  def set_ticket
    @ticket = Ticket.includes(:gate_one, :gate_two, :reported_by, :assigned_to).find(params[:ticket_id])
  end

  def gate_one_params
    params.require(:ticket_gate_one).permit(
      :problem_description,
      :reproduction_steps,
      :expected_behavior,
      :actual_behavior,
      :environment_context,
      :attachments_summary
    )
  end

  def gate_notice(complete, gate_name)
    complete ? "#{gate_name} is now complete." : "#{gate_name} saved as draft."
  end
end
