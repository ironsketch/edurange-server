class HomeController < ApplicationController
  def index
    if user_signed_in?
      @user = User.find(current_user.id)

      if @user.is_admin?
        @instructors = User.where role: 3
        @students = User.where role: 4

        begin
          @aws_vpc_cnt = AWS::EC2.new.vpcs.count
          @aws_instance_cnt = AWS::EC2.new.instances.count
        rescue => e
          @aws_vpc_cnt = nil
          @aws_instance_cnt = nil
        end
      end

    else
      redirect_to new_user_session_path
    end
  end
end