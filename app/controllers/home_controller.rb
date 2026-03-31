class HomeController < ApplicationController
  def index
    @ticket_counts = {
      draft: Ticket.status_draft.count,
      open: Ticket.status_open.count,
      in_progress: Ticket.status_in_progress.count,
      needs_review: Ticket.status_needs_review.count,
      resolved: Ticket.status_resolved.count,
      closed: Ticket.status_closed.count
    }

    @recent_tickets = Ticket.includes(:reported_by, :assigned_to, :gate_one, :gate_two)
                            .order(updated_at: :desc)
                            .limit(6)

    @recent_events = TicketEvent.includes(:ticket, :actor)
                                .recent_first
                                .limit(8)
  end
end
