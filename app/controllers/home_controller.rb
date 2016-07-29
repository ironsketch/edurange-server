class HomeController < ApplicationController
  def index
    if user_signed_in?
      user = User.find(current_user.id)
      if user.is_admin?
        redirect_to '/admin'
      elsif user.is_instructor?
        redirect_to '/instructor'
      elsif user.is_student?
        redirect_to '/student'
      end
    else
      redirect_to new_user_session_path
    end
  end
end