require 'pry'

class StudentGroup < ActiveRecord::Base
  belongs_to :user
  has_many   :student_group_users, dependent: :destroy
  has_many :users, through: :student_group_users

  validates :name, presence: true, uniqueness: { scope: :user, message: "already taken" } 

  # before_destroy :check_if_all

  # def check_if_all
  # 	if self.name == "All"
  # 		errors.add(:name, "can not delete Student Group All")
  # 		return false
  # 	end
  # 	true
  # end

  def user_add(*students)
    binding.pry
    students.each do |student|
      if user.students.include?(student)
        student_group_users.push(student_group_users.create(user: student))
      else
        errors.add(:user, "#{student.name} not found")
      end
    end
  end

end
