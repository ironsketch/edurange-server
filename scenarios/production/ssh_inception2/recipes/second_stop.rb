script "second_stop_script" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
 code <<-EOH
message="\\n### SECOND STOP ###\\n\\nTo go a level deeper, login to 10.0.0.15. You will need to use the ssh key 'id_rsa'.\\n\\n"

while read player; do
  player=$(echo -n $player)
  cd /home/$player
  
  echo -e $message > message 
  chmod 404 message
  echo 'cat message' >> .bashrc

  echo -e "$(edurange-get-var user $player third_stop_private_key)" > id_rsa 
  chown $player:$player id_rsa 
  chmod 400 id_rsa 

  echo $(edurange-get-var user $player secret_second_stop) > secret
  chown $player:$player secret
  chmod 400 secret
done </root/edurange/players
  EOH
end
