class TicketsController < ApplicationController
  before_action :set_ticket, only: %i[show edit update destroy]
  before_action :load_assignable_users, only: %i[new create edit update]

  def index
    @tickets = Ticket.includes(:reported_by, :assigned_to).recent_first
  end

  def show
    @ticket_policy = ticket_policy(@ticket)
    return if ticket_policy(@ticket).show?

    deny_access!
  end

  def new
    @ticket = Ticket.new(status: :draft, severity: :medium, domain: "bug_tracker")
    @ticket_policy = ticket_policy(@ticket)
    return if @ticket_policy.create?

    deny_access!
  end

  def create
    @ticket = current_user.reported_tickets.build
    policy = ticket_policy(@ticket)
    @ticket_policy = policy
    return deny_access! unless policy.create?

    permitted_attributes = permitted_ticket_attributes(policy)
    target_status = extract_target_status(permitted_attributes, default: @ticket.status)
    @ticket.assign_attributes(permitted_attributes.except("status"))

    transition_result = TicketTransitionService.call(
      ticket: @ticket,
      actor: current_user,
      from_status: nil,
      target_status: target_status,
      policy: policy
    )

    if !transition_result.success?
      @ticket.status = target_status
      flash.now[:alert] = transition_result.error
      render :new, status: :unprocessable_entity
      return
    end

    @ticket.status = target_status
    @ticket.assign_attributes(permitted_attributes.except("status"))
    @ticket.reported_by = current_user

    if @ticket.save
      TicketEventLogger.log_ticket_created!(ticket: @ticket, actor: current_user)
      sync_training_example_for(@ticket)
      redirect_to @ticket, notice: "Ticket created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @ticket_policy = ticket_policy(@ticket)
    return if @ticket_policy.update?

    deny_access!
  end

  def update
    policy = ticket_policy(@ticket)
    @ticket_policy = policy
    return deny_access! unless policy.update?

    permitted_attributes = permitted_ticket_attributes(policy)
    target_status = extract_target_status(permitted_attributes, default: @ticket.status)

    @ticket.assign_attributes(permitted_attributes.except("status"))

    transition_result = TicketTransitionService.call(
      ticket: @ticket,
      actor: current_user,
      from_status: @ticket.status,
      target_status: target_status,
      policy: policy
    )

    if !transition_result.success?
      flash.now[:alert] = transition_result.error
      render :edit, status: :unprocessable_entity
      return
    end

    @ticket.status = target_status

    if @ticket.save
      TicketEventLogger.log_ticket_updated!(ticket: @ticket, actor: current_user, changes: @ticket.saved_changes)
      sync_training_example_for(@ticket)
      redirect_to @ticket, notice: "Ticket updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    return deny_access! unless ticket_policy(@ticket).destroy?

    @ticket.destroy!
    redirect_to tickets_path, notice: "Ticket deleted successfully."
  end

  private

  def set_ticket
    @ticket = Ticket.includes(
      :reported_by,
      :assigned_to,
      :gate_one,
      :gate_two,
      :training_examples,
      { comments: :author },
      { events: :actor },
      { ticket_commits: :author }
    ).find(params[:id])
    @ticket_policy = ticket_policy(@ticket)
    @new_comment = TicketComment.new(ticket_id: @ticket.id)
    @new_ticket_commit = TicketCommit.new(ticket_id: @ticket.id)
    @latest_training_example = @ticket.latest_training_example
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

  def permitted_ticket_attributes(policy)
    ticket_params.slice(*policy.permitted_attributes.map(&:to_s))
  end

  def extract_target_status(permitted_attributes, default:)
    permitted_attributes["status"].presence || default
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
