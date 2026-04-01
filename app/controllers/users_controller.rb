class UsersController < ApplicationController
  before_action :require_admin!
  before_action :set_user, only: %i[edit update reset_password update_password deactivate reactivate]

  def index
    @query = params[:q].to_s.strip
    @role_filter = params[:role].to_s
    @state_filter = params[:state].to_s
    @all_users = User.includes(:user_events).order(:role, :name, :email)
    @users = @all_users.search(@query).with_role(@role_filter).with_state(@state_filter)
  end

  def new
    @user = User.new(role: :customer)
  end

  def create
    @user = User.new(user_params)

    if @user.save
      UserEventLogger.log_user_created!(user: @user, actor: current_user)
      redirect_to users_path, notice: "User created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_recent_user_events
  end

  def update
    if demoting_last_admin? || demoting_current_admin?
      redirect_to users_path, alert: "You cannot remove the final admin role from this account."
      return
    end

    if @user.update(user_update_params)
      UserEventLogger.log_user_updated!(user: @user, actor: current_user, changes: @user.saved_changes)
      redirect_to users_path, notice: "User updated successfully."
    else
      load_recent_user_events
      render :edit, status: :unprocessable_entity
    end
  end

  def deactivate
    if @user == current_user
      redirect_to users_path, alert: "You cannot deactivate the account you are currently signed into."
      return
    end

    if @user.role_admin? && last_admin?(@user)
      redirect_to users_path, alert: "You cannot deactivate the last admin account."
      return
    end

    if @user.update(active: false, deactivated_at: Time.current)
      UserEventLogger.log_deactivated!(user: @user, actor: current_user)
      redirect_to users_path, notice: "User deactivated successfully."
    else
      redirect_to users_path, alert: @user.errors.full_messages.to_sentence
    end
  end

  def reactivate
    if @user.update(active: true, deactivated_at: nil)
      UserEventLogger.log_reactivated!(user: @user, actor: current_user)
      redirect_to users_path, notice: "User reactivated successfully."
    else
      redirect_to users_path, alert: @user.errors.full_messages.to_sentence
    end
  end

  def reset_password
    load_recent_user_events
  end

  def update_password
    if @user.update(password_params)
      UserEventLogger.log_password_reset!(user: @user, actor: current_user)
      redirect_to users_path, notice: "Password reset successfully."
    else
      load_recent_user_events
      render :reset_password, status: :unprocessable_entity
    end
  end

  private

  def require_admin!
    require_role!(:admin)
  end

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :role, :password, :password_confirmation)
  end

  def user_update_params
    params.require(:user).permit(:name, :email, :role)
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def load_recent_user_events
    @user_events = @user.user_events.includes(:actor).recent_first.limit(20)
  end

  def last_admin?(user)
    user.role_admin? && User.where(role: :admin, active: true).where.not(id: user.id).none?
  end

  def demoting_last_admin?
    @user.role_admin? && user_update_params[:role].present? && user_update_params[:role] != "admin" && last_admin?(@user)
  end

  def demoting_current_admin?
    @user == current_user && user_update_params[:role].present? && user_update_params[:role] != "admin"
  end
end
