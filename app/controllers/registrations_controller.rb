class RegistrationsController < Devise::RegistrationsController
  before_filter :update_sanitized_params, if: :devise_controller?

  def update_sanitized_params
    devise_parameter_sanitizer.permit(:sign_up) {|u| u.permit(:name, :email, :password, :password_confirmation, :registration_code)}
    devise_parameter_sanitizer.permit(:account_update) {|u| u.permit(:name, :email, :password, :password_confirmation, :current_password)}
  end

  def create

    query = "registration_code = ? AND (role = 3 OR role = 2)"
    puts "query:#{query}"
    instructor = User.where(query, params[:user][:registration_code]).first
    if instructor.nil?
      query = "registration_code = ?"
      stugroup = StudentGroup.where(query, params[:user][:registration_code]).first
      if not stugroup.nil?
        if stugroup.user.role == "admin" or "instructor"
          instructor = stugroup.user
        end
      end
    end
    if params[:user][:registration_code] == '' or !instructor
      params[:user][:registration_code] = nil
      build_resource(sign_up_params)
      resource.errors.add :registration_code, " is not valid"
      respond_with resource
      return
    end
    params[:user][:registration_code] = nil

    build_resource(sign_up_params)
    resource_saved = resource.save
    yield resource if block_given?
    if resource_saved
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_flashing_format?
        sign_up(resource_name, resource)

        # assign to instructors default group
        sgu_all = instructor.student_groups.find_by(name: "All").student_group_users.new(user_id: resource.id)
        sgu_all.save

        if not stugroup.nil?
          sgu = stugroup.student_group_users.new(user_id: resource.id)
          sgu.save
        end

        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      
      clean_up_passwords resource
      @validatable = devise_mapping.validatable?
      if @validatable
        @minimum_password_length = resource_class.password_length.min
      end
      respond_with resource
    end
  end
end
