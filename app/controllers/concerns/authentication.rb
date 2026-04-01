module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :set_current_user
    helper_method :current_user, :signed_in?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :authenticate_user!, **options
    end
  end

  private

  def authenticate_user!
    return if signed_in?

    store_return_location
    redirect_to new_session_path, alert: "Please sign in to continue."
  end

  def set_current_user
    Current.user = current_user
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id], active: true) if session[:user_id].present?
  end

  def signed_in?
    current_user.present?
  end

  def sign_in(user)
    return_to = session[:return_to]
    reset_session
    session[:return_to] = return_to if return_to.present?
    session[:user_id] = user.id
    user.update_column(:last_seen_at, Time.current)
    Current.user = user
  end

  def sign_out
    Current.user = nil
    reset_session
  end

  def require_role!(*roles)
    return if signed_in? && roles.any? { |role| current_user.public_send("role_#{role}?") }

    redirect_to root_path, alert: "You do not have access to that page."
  end

  def after_authentication_path
    session.delete(:return_to) || root_path
  end

  def store_return_location
    return unless request.get?
    return if request.xhr?

    session[:return_to] = request.fullpath
  end
end
