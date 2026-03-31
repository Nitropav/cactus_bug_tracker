class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    redirect_to root_path if signed_in?
  end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)

    if user&.authenticate(params[:password].to_s)
      sign_in(user)
      redirect_to after_authentication_path, notice: "Signed in successfully."
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    sign_out
    redirect_to new_session_path, notice: "Signed out successfully."
  end
end
