class TicketCommentsController < ApplicationController
  before_action :set_ticket

  def create
    return deny_access! unless ticket_policy(@ticket).comment?

    @comment = @ticket.comments.build(comment_params.merge(author: current_user))

    if @comment.save
      TicketEventLogger.log_comment_created!(ticket: @ticket, actor: current_user, comment: @comment)
      redirect_to ticket_path(@ticket, anchor: "comments"), notice: "Comment added."
    else
      redirect_to ticket_path(@ticket, anchor: "comments"), alert: "Comment could not be added."
    end
  end

  private

  def set_ticket
    @ticket = Ticket.find(params[:ticket_id])
  end

  def comment_params
    params.require(:ticket_comment).permit(:body)
  end
end
