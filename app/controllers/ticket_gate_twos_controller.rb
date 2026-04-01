class TicketGateTwosController < ApplicationController
  before_action :set_ticket

  def update
    return deny_access! unless ticket_policy(@ticket).update_gate_two?

    if @ticket.gate_two.update(gate_two_params)
      TicketEventLogger.log_gate_updated!(
        ticket: @ticket,
        actor: current_user,
        gate_name: "Gate 2",
        complete: @ticket.gate_two.complete?,
        changed_fields: @ticket.gate_two.saved_changes.keys - %w[updated_at completed_at]
      )
      sync_training_example_for(@ticket)
      redirect_to @ticket, notice: gate_notice(@ticket.gate_two.complete?, "Gate 2")
    else
      redirect_to @ticket, alert: "Gate 2 could not be updated."
    end
  end

  private

  def set_ticket
    @ticket = Ticket.includes(:gate_one, :gate_two, :reported_by, :assigned_to).find(params[:ticket_id])
  end

  def gate_two_params
    params.require(:ticket_gate_two).permit(
      :root_cause,
      :fix_summary,
      :verification_steps,
      :primary_commit_sha,
      :primary_pull_request_url
    )
  end

  def gate_notice(complete, gate_name)
    complete ? "#{gate_name} is now complete." : "#{gate_name} saved as draft."
  end
end
