class User < ApplicationRecord
  has_secure_password

  ROLES = {
    reporter: 0,
    developer: 1,
    reviewer: 2,
    admin: 3
  }.freeze

  attribute :role, :integer, default: ROLES[:reporter]

  enum :role, ROLES, prefix: true

  normalizes :email, with: ->(value) { value.to_s.strip.downcase }

  has_many :reported_tickets,
           class_name: "Ticket",
           foreign_key: :reported_by_id,
           inverse_of: :reported_by,
           dependent: :nullify
  has_many :assigned_tickets,
           class_name: "Ticket",
           foreign_key: :assigned_to_id,
           inverse_of: :assigned_to,
           dependent: :nullify
  has_many :ticket_comments,
           foreign_key: :author_id,
           inverse_of: :author,
           dependent: :nullify
  has_many :ticket_events,
           foreign_key: :actor_id,
           inverse_of: :actor,
           dependent: :nullify

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true

  def display_role
    role.humanize
  end

  def staff?
    role_developer? || role_reviewer? || role_admin?
  end

  def can_review?
    role_reviewer? || role_admin?
  end

  def can_develop?
    role_developer? || role_admin?
  end
end
