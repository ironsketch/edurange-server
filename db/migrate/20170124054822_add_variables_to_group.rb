class AddVariablesToGroup < ActiveRecord::Migration
  def change
    add_column :groups, :variables, :string
  end
end
