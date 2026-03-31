class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Authentication

  before_action :authenticate_user!
  helper_method :ticket_creation_policy

  private

  def ticket_policy(ticket)
    TicketPolicy.new(current_user, ticket)
  end

  def ticket_creation_policy
    @ticket_creation_policy ||= TicketPolicy.new(current_user, current_user&.reported_tickets&.build || Ticket.new)
  end

  def deny_access!(message = "You do not have access to that action.")
    redirect_back fallback_location: root_path, alert: message
  end
end
