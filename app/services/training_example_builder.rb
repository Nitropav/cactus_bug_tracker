class TrainingExampleBuilder
  Result = Struct.new(:success?, :training_example, :created, keyword_init: true)

  def self.call(ticket:, actor: nil)
    new(ticket:, actor:).call
  end

  def initialize(ticket:, actor:)
    @ticket = ticket
    @actor = actor
  end

  def call
    training_example = pending_training_example || ticket.training_examples.build(status: :pending_review)
    created = training_example.new_record?

    training_example.assign_attributes(training_example_attributes)
    training_example.generated_at = Time.current
    training_example.status = :pending_review
    training_example.reviewed_by = nil
    training_example.reviewed_at = nil
    training_example.review_notes = nil
    training_example.save!

    TicketEventLogger.log_training_example_generated!(
      ticket: ticket,
      actor: actor,
      training_example: training_example,
      created: created
    )

    Result.new(success?: true, training_example: training_example, created: created)
  end

  private

  attr_reader :ticket, :actor

  def pending_training_example
    ticket.training_examples.status_pending_review.order(created_at: :desc).first
  end

  def training_example_attributes
    {
      title: ticket.title,
      problem_description: ticket.gate_one&.problem_description,
      reproduction_steps: ticket.gate_one&.reproduction_steps,
      expected_behavior: ticket.gate_one&.expected_behavior,
      actual_behavior: ticket.gate_one&.actual_behavior,
      environment_context: ticket.gate_one&.environment_context,
      root_cause: ticket.gate_two&.root_cause,
      fix_summary: ticket.gate_two&.fix_summary,
      verification_steps: ticket.gate_two&.verification_steps,
      metadata: build_metadata
    }
  end

  def build_metadata
    {
      "ticket_id" => ticket.id,
      "ticket_summary" => ticket.summary,
      "source_ticket_status" => ticket.status,
      "domain" => ticket.domain,
      "severity" => ticket.severity,
      "external_reference" => ticket.external_reference,
      "reported_by" => user_metadata(ticket.reported_by),
      "assigned_to" => ticket.assigned_to ? user_metadata(ticket.assigned_to) : nil,
      "gate_one_completed_at" => ticket.gate_one&.completed_at,
      "gate_two_completed_at" => ticket.gate_two&.completed_at,
      "primary_commit_sha" => ticket.gate_two&.primary_commit_sha,
      "primary_pull_request_url" => ticket.gate_two&.primary_pull_request_url,
      "commit_shas" => ticket.ticket_commits.filter_map(&:commit_sha).uniq,
      "pull_request_urls" => ticket.ticket_commits.filter_map(&:pull_request_url).uniq,
      "commit_links" => ticket.ticket_commits.map do |ticket_commit|
        {
          "commit_sha" => ticket_commit.commit_sha,
          "pull_request_url" => ticket_commit.pull_request_url,
          "repository_name" => ticket_commit.repository_name,
          "notes" => ticket_commit.notes
        }
      end,
      "comment_count" => ticket.comments.size,
      "recent_comment_previews" => ticket.comments.order(created_at: :desc).limit(5).map do |comment|
        {
          "author" => comment.author.name,
          "preview" => comment.preview,
          "created_at" => comment.created_at
        }
      end
    }
  end

  def user_metadata(user)
    {
      "id" => user.id,
      "name" => user.name,
      "email" => user.email,
      "role" => user.role
    }
  end
end
