script "fourth_stop" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH

message="\\\\n\\n### FOURTH STOP ###\n\\n'It's been six hours. Dreams move one... one-hundredth the speed of reality, and dog time is one-seventh human time. So y'know, every day here is like a minute. It's like Inception, Morty, so if it's confusing and stupid, then so is everyone's favorite movie.'\\n\\nThere is loose ftp server on the network which might contain something useful...\\n\\nHelpful commands: nmap, ssh, ftp - ls, get, help\\n\\n"

while read player; do
  player=$(echo -n $player)
  cd /home/$player

  echo -e $message > message
  chmod 404 message
  echo 'cat message' >> .bashrc

  # change password
  password=$(edurange-get-var user $player fourth_stop_password)
  echo -e "${password}\\n${password}" | passwd $player
  
  # encrypt fifth stop password
  password=$(edurange-get-var user $player fifth_stop_password)
  echo $password > passfile
  openssl aes-256-cbc -e -pass pass:$(edurange-get-var instance fifth_stop_password_key) -in passfile -out encryptedpassword 
  chown $player:$player encryptedpassword
  chmod 400 encryptedpassword
  rm passfile

  echo -e "#!/bin/bash
openssl aes-256-cbc -d -in encryptedpassword -out password
chmod 400 password
cat password" > decryptpass
  chmod 505 decryptpass

  echo $(edurange-get-var user $player secret_fourth_stop) > secret
  chown $player:$player secret
  chmod 400 secret
done </root/edurange/players

# block traffic from ThirdStop. players must find a way around this
iptables -A INPUT -s 10.0.0.15 -j DROP
EOH
end
