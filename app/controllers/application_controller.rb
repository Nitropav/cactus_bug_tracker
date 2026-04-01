class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Authentication

  before_action :authenticate_user!
  helper_method :ticket_creation_policy, :training_example_policy

  private

  def ticket_policy(ticket)
    TicketPolicy.new(current_user, ticket)
  end

  def ticket_creation_policy
    @ticket_creation_policy ||= TicketPolicy.new(current_user, current_user&.reported_tickets&.build || Ticket.new)
  end

  def training_example_policy(training_example)
    TrainingExamplePolicy.new(current_user, training_example)
  end

  def deny_access!(message = "You do not have access to that action.")
    redirect_back fallback_location: root_path, alert: message
  end

  def sync_training_example_for(ticket)
    return unless ticket.status_resolved? || ticket.status_closed?

    TrainingExampleBuilder.call(ticket: ticket, actor: current_user)
  rescue StandardError => error
    Rails.logger.error("Training example sync failed for ticket #{ticket.id}: #{error.class}: #{error.message}")
  end
end
