class TicketCommitsController < ApplicationController
  before_action :set_ticket

  def create
    return deny_access! unless ticket_policy(@ticket).manage_commits?

    @ticket_commit = @ticket.ticket_commits.build(ticket_commit_params)
    @ticket_commit.author = current_user

    if @ticket_commit.save
      TicketEventLogger.log_commit_linked!(ticket: @ticket, actor: current_user, ticket_commit: @ticket_commit)
      redirect_to ticket_path(@ticket, anchor: "implementation-links"), notice: "Implementation link added."
    else
      redirect_to ticket_path(@ticket, anchor: "implementation-links"), alert: @ticket_commit.errors.full_messages.to_sentence
    end
  end

  def destroy
    return deny_access! unless ticket_policy(@ticket).manage_commits?

    @ticket_commit = @ticket.ticket_commits.find(params[:id])
    TicketEventLogger.log_commit_unlinked!(ticket: @ticket, actor: current_user, ticket_commit: @ticket_commit)
    @ticket_commit.destroy!

    redirect_to ticket_path(@ticket, anchor: "implementation-links"), notice: "Implementation link removed."
  end

  private

  def set_ticket
    @ticket = Ticket.find(params[:ticket_id])
  end

  def ticket_commit_params
    params.require(:ticket_commit).permit(:commit_sha, :pull_request_url, :repository_name, :notes)
  end
end
