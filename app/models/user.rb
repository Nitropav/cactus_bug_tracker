class User < ApplicationRecord
  has_secure_password

  ROLES = {
    customer: 0,
    developer: 1,
    support_agent: 2,
    admin: 3
  }.freeze

  attribute :role, :integer, default: ROLES[:customer]

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
  has_many :ticket_commits,
           foreign_key: :author_id,
           inverse_of: :author,
           dependent: :nullify
  has_many :reviewed_training_examples,
           class_name: "TrainingExample",
           foreign_key: :reviewed_by_id,
           inverse_of: :reviewed_by,
           dependent: :nullify
  has_many :user_events, dependent: :destroy, inverse_of: :user
  has_many :acted_user_events,
           class_name: "UserEvent",
           foreign_key: :actor_id,
           inverse_of: :actor,
           dependent: :nullify

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :active, inclusion: { in: [true, false] }

  scope :recent_first, -> { order(created_at: :desc) }
  scope :search, lambda { |query|
    normalized_query = query.to_s.strip
    normalized_query.present? ? where("name ILIKE :query OR email ILIKE :query", query: "%#{normalized_query}%") : all
  }
  scope :with_role, ->(role) { role.to_s.presence && roles.key?(role.to_s) ? where(role: role) : all }
  scope :with_state, lambda { |state|
    case state.to_s
    when "active" then where(active: true)
    when "inactive" then where(active: false)
    else all
    end
  }

  def display_role
    role.humanize
  end

  def active?
    !!self[:active]
  end

  def inactive?
    !active?
  end

  def display_state
    active? ? "Active" : "Disabled"
  end

  def staff?
    role_support_agent? || role_developer? || role_admin?
  end

  def can_review?
    role_developer? || role_admin?
  end

  def can_develop?
    role_developer? || role_admin?
  end

  def can_support?
    role_support_agent? || role_admin?
  end
end
