class UserPolicy < ApplicationPolicy

  def index?
    @user.is_admin?
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
