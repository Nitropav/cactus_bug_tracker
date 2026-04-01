class TrainingExamplesController < ApplicationController
  before_action :set_training_example, only: %i[show approve reject]
  before_action :require_training_example_index_access!, only: %i[index export]
  before_action :require_training_example_show_access!, only: :show
  before_action :require_training_example_review_access!, only: %i[approve reject]

  def index
    @status_filter = params[:status].to_s
    @training_examples = TrainingExample.includes(:ticket, :reviewed_by).pending_review_first
    @training_examples = @training_examples.public_send("status_#{@status_filter}") if valid_status_filter?
    @approved_count = TrainingExample.status_approved.count
  end

  def show
  end

  def export
    return deny_access! unless training_example_policy(TrainingExample.new).export?

    result = TrainingExamples::JsonlExporter.call(scope: TrainingExample.all)

    if result.count.zero?
      redirect_to training_examples_path(status: "approved"), alert: "No approved training examples are ready for export."
      return
    end

    send_data(
      result.content,
      filename: result.filename,
      type: "application/x-ndjson; charset=utf-8",
      disposition: "attachment"
    )
  end

  def approve
    update_review_status!(:approved, notice: "Training example approved.")
  end

  def reject
    update_review_status!(:rejected, notice: "Training example rejected.")
  end

  private

  def set_training_example
    @training_example = TrainingExample.includes(:reviewed_by, ticket: %i[reported_by assigned_to]).find(params[:id])
  end

  def require_training_example_index_access!
    return if training_example_policy(TrainingExample.new).index?

    deny_access!
  end

  def require_training_example_show_access!
    return if training_example_policy(@training_example).show?

    deny_access!
  end

  def require_training_example_review_access!
    allowed = action_name == "approve" ? training_example_policy(@training_example).approve? : training_example_policy(@training_example).reject?
    return if allowed

    deny_access!
  end

  def valid_status_filter?
    @status_filter.present? && TrainingExample.statuses.key?(@status_filter)
  end

  def update_review_status!(status, notice:)
    @training_example.update!(
      status: status,
      reviewed_by: current_user,
      reviewed_at: Time.current,
      review_notes: params.dig(:training_example, :review_notes).to_s.strip.presence
    )

    TicketEventLogger.log_training_example_reviewed!(
      ticket: @training_example.ticket,
      actor: current_user,
      training_example: @training_example,
      status: status
    )

    redirect_to @training_example, notice: notice
  end
end
