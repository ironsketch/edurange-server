class ApplicationController < ActionController::Base

# before_filter :authenticate_user!

  include Pundit
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :nat_instance

  private

  def nat_instance(nat_instance = nil)
    @nat_instance ||= nat_instance
  end

  def user_not_authorized
    respond_to do |format|
      format.html do
        flash[:alert] = "Access denied."
        redirect_to (:back || root_path)
      end

      format.json { head :forbidden }
    end
  end

  def authenticate_admin
    if user_signed_in?
      @user = User.find(current_user.id)
      if @user.is_admin?
        return
      end
    end
    redirect_to '/'
  end

  def authenticate_instructor
    if user_signed_in?
      @user = User.find(current_user.id)
      if @user.is_instructor?
        return
      end
    end
    redirect_to '/'
  end

  def authenticate_admin_or_instructor
    if user_signed_in?
      @user = User.find(current_user.id)
      if @user.is_admin? || @user.is_instructor?
        return
      end
    end
    redirect_to '/'
  end

  def authenticate_student
    if user_signed_in?
      @user = User.find(current_user.id)
      if @user.is_student?
        return
      end
    end
    redirect_to '/'
  end

end
