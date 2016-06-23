class UsersController < ApplicationController
  before_filter :authenticate_user!
  after_action :verify_authorized

  def index
    @users = User.all
    authorize @users
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
      respond_to do |format|
        format.html { redirect_to users_path }
        format.json { render json: @user.to_json }
      end
    end
  end

  def destroy
    user = User.find(params[:id])
    authorize user

    user.destroy

    respond_to do |format|
      format.html { redirect_to users_path }
      format.json { head :success }
    end
  end

  private

  def secure_params
    params.require(:user).permit(:role)
  end

end
