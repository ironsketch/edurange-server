class UsersController < ApplicationController
  before_filter :authenticate_user!
  after_action :verify_authorized, except: [:index, :batch_action]
  after_action :verify_policy_scoped, only: :index

  def index
    @users = policy_scope(User)

    respond_to do |format|
      format.html
      format.json { render json: @users.to_json }
    end
  end

  def show
    @user = User.find(params[:id])
    authorize @user

    respond_to do |format|
      format.html
      format.json { render json: @user.to_json }
    end
  end

  def update
    @user = User.find(params[:id])
    authorize @user

    if @user.update_attributes(secure_params)
      flash[:notice] = "#{@user.name} updated"
      respond_to do |format|
        format.html { redirect_to (:back || user_path(@user)) }
        format.json { render json: @user.to_json }
      end
    else
      respond_to do |format|
        flash[:error] = @user.errors.full_messages.to_sentence
        format.html { redirect_to (:back || user_path(@user)) }
        format.json { render json: { "errors" => @user.errors.to_json } }
      end
    end
  end

  def destroy
    user = User.find(params[:id])
    authorize user
    name = user.name
    user.destroy

    flash[:notice] = "#{name} deleted"
    respond_to do |format|
      format.html { redirect_to (:back || users_path) }
      format.json { head :success }
    end
  end

  def batch_action
    if not params[:ids]
      redirect_to :back || users_path
    elsif params[:commit] == "delete"
      destroy_selected
    elsif params[:commit] == "update"
      update_selected
    elsif params[:commit] == "add users"
      add_selected_to_student_group
    else
      redirect_to :back || users_path
    end
  end

  def destroy_selected
    names = []
    params[:ids].each do |id|
      user = User.find(id)
      authorize user, :destroy?
      names << user.name
      user.destroy
    end

    flash[:notice] = "#{names.to_sentence} deleted"
    respond_to do |format|
      format.html { redirect_to (:back || users_path) }
      format.json { head :success }
    end
  end

  def update_selected
    names = []
    params[:ids].each do |id|
      user = User.find(id)
      authorize user, :update?
      names << user.name
      user.update_attributes(secure_params)
    end

    flash[:notice] = "#{names.to_sentence} updated"
    respond_to do |format|
      format.html { redirect_to (:back || users_path) }
      format.json { head :success }
    end
  end

  def add_selected_to_student_group
    student_group = StudentGroup.find(params[:student_group])
    names = []

    unless student_group.nil?
      student_group.user_add(*User.find(params[:ids]))
    else
      flash[:error] = "Couldn't find student group"
    end

    if student_group.errors.any?
      flash[:error] = student_group.errors.full_messages.to_sentence
    else
      flash[:notice] = "#{names.to_sentence} added to #{student_group.name}"
    end

    respond_to do |format|
      format.html { redirect_to (:back || users_path) }
      format.json { head :success }
    end
  end

  private

  def secure_params
    params.permit(:role, :organization, :student_group)
  end

end
