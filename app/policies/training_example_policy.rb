class TrainingExamplePolicy
  attr_reader :user, :training_example

  def initialize(user, training_example)
    @user = user
    @training_example = training_example
  end

  def index?
    review_access?
  end

  def show?
    review_access?
  end

  def approve?
    review_access?
  end

  def reject?
    review_access?
  end

  def export?
    review_access?
  end

  private

  def review_access?
    user.present? && (user.role_developer? || user.role_admin?)
  end
end
