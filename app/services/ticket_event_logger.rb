class TicketEventLogger
  def self.log!(ticket:, actor:, event_type:, message:, metadata: {})
    ticket.events.create!(
      actor: actor,
      event_type: event_type,
      message: message,
      metadata: metadata
    )
  end

  def self.log_ticket_created!(ticket:, actor:)
    log!(
      ticket: ticket,
      actor: actor,
      event_type: "ticket_created",
      message: "Ticket created with status #{ticket.display_status.downcase}."
    )
  end

  def self.log_ticket_updated!(ticket:, actor:, changes:)
    tracked = changes.slice("title", "summary", "status", "severity", "domain", "assigned_to_id", "external_reference")
    return if tracked.empty?

    if tracked.key?("status")
      from, to = tracked["status"]
      log!(
        ticket: ticket,
        actor: actor,
        event_type: "status_changed",
        message: "Status changed from #{display_status(from)} to #{display_status(to)}.",
        metadata: { from: from, to: to }
      )
    end

    changed_labels = tracked.keys.reject { |key| key == "status" }.map { |key| key.humanize(capitalize: false) }
    return if changed_labels.empty?

    log!(
      ticket: ticket,
      actor: actor,
      event_type: "ticket_updated",
      message: "Updated #{changed_labels.join(', ')}.",
      metadata: { fields: changed_labels }
    )
  end

  def self.log_gate_updated!(ticket:, actor:, gate_name:, complete:, changed_fields:)
    fields = Array(changed_fields).map { |field| field.to_s.humanize(capitalize: false) }

    log!(
      ticket: ticket,
      actor: actor,
      event_type: "#{gate_name.underscore}_updated",
      message: "#{gate_name} #{complete ? 'completed' : 'saved as draft'}#{fields.any? ? " (updated: #{fields.join(', ')})" : ''}.",
      metadata: { complete: complete, fields: fields }
    )
  end

  def self.log_comment_created!(ticket:, actor:, comment:)
    log!(
      ticket: ticket,
      actor: actor,
      event_type: "comment_created",
      message: "Comment added: #{comment.preview}",
      metadata: { comment_id: comment.id }
    )
  end

  def self.log_commit_linked!(ticket:, actor:, ticket_commit:)
    log!(
      ticket: ticket,
      actor: actor,
      event_type: "commit_linked",
      message: "Linked #{commit_link_message(ticket_commit)}.",
      metadata: {
        ticket_commit_id: ticket_commit.id,
        commit_sha: ticket_commit.commit_sha,
        pull_request_url: ticket_commit.pull_request_url,
        repository_name: ticket_commit.repository_name
      }
    )
  end

  def self.log_commit_unlinked!(ticket:, actor:, ticket_commit:)
    log!(
      ticket: ticket,
      actor: actor,
      event_type: "commit_unlinked",
      message: "Removed #{commit_link_message(ticket_commit)}.",
      metadata: {
        ticket_commit_id: ticket_commit.id,
        commit_sha: ticket_commit.commit_sha,
        pull_request_url: ticket_commit.pull_request_url,
        repository_name: ticket_commit.repository_name
      }
    )
  end

  def self.log_training_example_generated!(ticket:, actor:, training_example:, created:)
    log!(
      ticket: ticket,
      actor: actor,
      event_type: "training_example_generated",
      message: "#{created ? 'Generated' : 'Refreshed'} training example draft ##{training_example.id}.",
      metadata: {
        training_example_id: training_example.id,
        status: training_example.status
      }
    )
  end

  def self.log_training_example_reviewed!(ticket:, actor:, training_example:, status:)
    log!(
      ticket: ticket,
      actor: actor,
      event_type: "training_example_#{status}",
      message: "Training example ##{training_example.id} #{status.to_s.humanize.downcase}.",
      metadata: {
        training_example_id: training_example.id,
        status: status
      }
    )
  end

  def self.display_status(value)
    Ticket.statuses.invert.fetch(value, value.to_s).to_s.humanize.downcase
  end

  def self.commit_link_message(ticket_commit)
    parts = []
    parts << "commit #{ticket_commit.short_commit_sha}" if ticket_commit.commit_sha.present?
    parts << "PR" if ticket_commit.pull_request_url.present?
    parts << "for #{ticket_commit.repository_name}" if ticket_commit.repository_name.present?
    parts.join(" ").presence || "implementation link"
  end
end
