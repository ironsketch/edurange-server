class StudentGroupsController < ApplicationController
  #before_action :authenticate_instructor

  # All this functionality should be moved to the instructor controller

  # def index
  #   # @message = params[:message]
  #   student_groups = StudentGroup.where :instructor_id => current_user.id
  #   @named_array = {}

  #   student_groups.each do |student_group|
  #     if !@named_array.key? student_group.name
  #       @named_array[student_group.name] = []
  #     end

  #     if student_group.student_id != current_user.id
  #       user = User.find(student_group.student_id)
  #       @named_array[student_group.name].push user
  #     end
  #   end
  # end

   def create
     @student_group = current_user.student_groups.create(student_group_params)

     if @student_group.errors.any?
       flash[:error] = @student_group.errors.full_messages.to_sentence
     else
       flash[:notice] = "#{@student_group.name} created!"
     end

     redirect_to (:back || root_url)
   end

   def destroy
     student_group = current_user.student_groups.find(params[:id])

     if not student_group.destroy
       flash[:errors] = student_group.errors.full_messages.to_sentence
     else
       flash[:notice] = "#{student_group.name} destroyed"
     end

     redirect_to (:back || root_url)
   end

  # def add_to
  #   user = User.find_by_email params[:email]
  #   if user and user.is_student?
  #     record = StudentGroup.where(
  #                                 :instructor_id => current_user.id, 
  #                                 :name => params[:group_name], 
  #                                 :student_id => user.id
  #                                 )
  #     if record.blank?
  #       StudentGroup.create(
  #                           :instructor_id => current_user.id, 
  #                           :name => params[:group_name], 
  #                           :student_id => user.id
  #                           )
  #     else
  #       message = "student already in group"
  #     end
  #   else
  #     # flash message
  #   end
  #   redirect_to '/student_groups'
  # end

  # def remove_from
  #   user = User.find_by_email params[:email]
  #   if user
  #     StudentGroup.where(
  #                       :instructor_id => current_user.id, 
  #                       :name => params[:group_name],
  #                       :student_id => user.id
  #                       ).destroy_all
  #   end
  #   redirect_to '/student_groups'
  # end

  private

  def student_group_params
    params.require(:student_group).permit(:name)
  end

end
