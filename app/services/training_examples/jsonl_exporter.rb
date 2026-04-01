require "json"

module TrainingExamples
  class JsonlExporter
    Result = Struct.new(:content, :filename, :count, :exported_ids, :generated_at, keyword_init: true)

    def self.call(scope: TrainingExample.all)
      new(scope:).call
    end

    def initialize(scope:)
      @scope = scope
    end

    def call
      approved_examples = scope.status_approved.includes(:ticket, :reviewed_by).order(:id).to_a
      generated_at = Time.current
      content = approved_examples.map { |training_example| JSON.generate(export_payload_for(training_example, generated_at:)) }.join("\n")

      if approved_examples.any?
        TrainingExample.where(id: approved_examples.map(&:id)).update_all(exported_at: generated_at, updated_at: generated_at)
      end

      Result.new(
        content: content,
        filename: "training_examples_approved_#{generated_at.utc.strftime('%Y%m%d_%H%M%S')}.jsonl",
        count: approved_examples.count,
        exported_ids: approved_examples.map(&:id),
        generated_at: generated_at
      )
    end

    private

    attr_reader :scope

    def export_payload_for(training_example, generated_at:)
      {
        training_example_id: training_example.id,
        ticket_id: training_example.ticket_id,
        title: training_example.title,
        review_status: training_example.status,
        generated_at: training_example.generated_timestamp&.utc&.iso8601,
        reviewed_at: training_example.reviewed_at&.utc&.iso8601,
        exported_at: generated_at.utc.iso8601,
        reviewed_by: reviewed_by_payload(training_example.reviewed_by),
        source_ticket_status: training_example.source_ticket_status,
        domain: training_example.metadata["domain"],
        severity: training_example.metadata["severity"],
        external_reference: training_example.metadata["external_reference"],
        problem_description: training_example.problem_description,
        reproduction_steps: training_example.reproduction_steps,
        expected_behavior: training_example.expected_behavior,
        actual_behavior: training_example.actual_behavior,
        environment_context: training_example.environment_context,
        root_cause: training_example.root_cause,
        fix_summary: training_example.fix_summary,
        verification_steps: training_example.verification_steps,
        review_notes: training_example.review_notes,
        commit_shas: training_example.commit_shas,
        pull_request_urls: training_example.pull_request_urls,
        metadata: training_example.metadata
      }
    end

    def reviewed_by_payload(user)
      return nil unless user

      {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role
      }
    end
  end
end
