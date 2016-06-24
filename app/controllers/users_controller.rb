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
        format.html { redirect_to users_path }
        format.json { render json: @user.to_json }
      end
    else
      respond_to do |format|
        flash[:error] = @user.errors.full_messages.to_sentence
        format.html { redirect_to users_path }
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
    if params[:commit] == "delete"
      destroy_selected
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

  private

  def secure_params
    params.require(:user).permit(:role)
  end

end
