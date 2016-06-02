class AddResourceInfoToStatistics < ActiveRecord::Migration
  def change
    add_column :statistics, :resource_info, :string
  end
end
