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
  end
end
