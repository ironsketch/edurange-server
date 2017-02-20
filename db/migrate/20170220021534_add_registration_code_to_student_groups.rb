class AddRegistrationCodeToStudentGroups < ActiveRecord::Migration
  def change
    add_column :student_groups, :registration_code, :string
  end
end
