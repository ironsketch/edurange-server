class AddIpVisibleToInstanceGroup < ActiveRecord::Migration
  def change
    add_column :instance_groups, :ip_visible, :boolean, default: true
  end
end
