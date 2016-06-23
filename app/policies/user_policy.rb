class UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if @user.is_admin?
        User.all
      else
        @user.students
      end
    end
  end

  def index?
    not @user.students.empty?
  end

  def show?
    @user.is_admin? || @user.students.include?(@record)
  end

  def update?
    @user.is_admin? || @user.students.include?(@record)
  end

  def destroy?
    @user.is_admin? || @user.students.include?(@record)
  end

end
