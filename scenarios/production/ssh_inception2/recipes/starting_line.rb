script "starting_line_script" do
  interpreter "bash"
  user "root"
  code <<-EOH
message="\\n### STARTING LINE\\n\\nGo a level deeper. You will find the next host at 10.0.0.7. The trick is that the ssh port has been changed to 123. Good luck!\\n\\n" 

while read player; do
  player=$(echo -n $player)
  cd /home/$player
  echo -e $message > message
  chmod 404 message 
  echo 'cat message' >> .bashrc

  echo $(edurange-get-var user $player secret_starting_line) > secret
  chown $player:$player secret
  chmod 400 secret

done </root/edurange/players
  EOH
end
