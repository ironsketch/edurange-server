class AddPublicIpAddressToInstance < ActiveRecord::Migration
  def change
    add_column :instances, :ip_address_public, :string
  end
end
