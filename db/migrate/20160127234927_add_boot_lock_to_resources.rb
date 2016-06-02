class AddBootLockToResources < ActiveRecord::Migration
  def change
    add_column :scenarios, :boot_code, :string, default: ""
    add_column :clouds, :boot_code, :string, default: ""
    add_column :subnets, :boot_code, :string, default: ""
    add_column :instances, :boot_code, :string, default: ""
  end
end
