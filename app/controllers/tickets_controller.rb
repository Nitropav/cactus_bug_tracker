class TicketsController < ApplicationController
  before_action :set_ticket, only: %i[show edit update destroy]
  before_action :load_assignable_users, only: %i[new create edit update]

  def index
    @tickets = Ticket.includes(:reported_by, :assigned_to).recent_first
  end

  def show; end

  def new
    @ticket = Ticket.new(status: :draft, severity: :medium, domain: "bug_tracker")
  end

  def create
    @ticket = current_user.reported_tickets.build(ticket_params)

    if transition_blocked?(@ticket)
      flash.now[:alert] = transition_error_message(@ticket.status)
      render :new, status: :unprocessable_entity
    elsif @ticket.save
      TicketEventLogger.log_ticket_created!(ticket: @ticket, actor: current_user)
      redirect_to @ticket, notice: "Ticket created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    @ticket.assign_attributes(ticket_params)

    if transition_blocked?(@ticket)
      flash.now[:alert] = transition_error_message(@ticket.status)
      render :edit, status: :unprocessable_entity
    elsif @ticket.save
      TicketEventLogger.log_ticket_updated!(ticket: @ticket, actor: current_user, changes: @ticket.saved_changes)
      redirect_to @ticket, notice: "Ticket updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @ticket.destroy!
    redirect_to tickets_path, notice: "Ticket deleted successfully."
  end

  private

  def set_ticket
    @ticket = Ticket.includes(:reported_by, :assigned_to, :gate_one, :gate_two, comments: :author, events: :actor).find(params[:id])
    @new_comment = @ticket.comments.build
    @event_filter = normalized_event_filter
    @event_order = normalized_order_param(params[:event_order], default: "newest")
    @comment_order = normalized_order_param(params[:comment_order], default: "newest")
    @visible_events = build_visible_events
    @visible_comments = build_visible_comments
  end

  def load_assignable_users
    @assignable_users = User.order(:name)
  end

  def ticket_params
    params.require(:ticket).permit(:title, :summary, :status, :severity, :domain, :assigned_to_id, :external_reference)
  end

  def transition_blocked?(ticket)
    return false if ticket.status.blank?

    !ticket.can_transition_to?(ticket.status)
  end

  def transition_error_message(status)
    case status.to_s
    when "open", "in_progress", "needs_review"
      "Gate 1 must be complete before the ticket can move into active work."
    when "resolved", "closed"
      "Both Gate 1 and Gate 2 must be complete before the ticket can be resolved or closed."
    else
      "That status change is not allowed yet."
    end
  end

  def normalized_event_filter
    value = params[:event_filter].to_s
    TicketEvent.filter_options.include?(value) ? value : "all"
  end

  def normalized_order_param(value, default:)
    value.to_s == "oldest" ? "oldest" : default
  end

  def build_visible_events
    scoped = @ticket.events.filtered_by(@event_filter)
    @event_order == "oldest" ? scoped.chronological : scoped.recent_first
  end

  def build_visible_comments
    @comment_order == "oldest" ? @ticket.comments.chronological : @ticket.comments.order(created_at: :desc)
  end
end
