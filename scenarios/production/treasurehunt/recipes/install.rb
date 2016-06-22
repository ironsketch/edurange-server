script "install_treasure_hunt" do

  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
  cd /root
  git clone https://github.com/edurange/scenario-treasure-hunt
  cd scenario-treasure-hunt
  ./install
  EOH

end