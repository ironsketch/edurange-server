script "second_stop_script" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
 code <<-EOH
message=$(cat << "EOF"

      ::::::::  :::::::::: ::::::::   ::::::::  ::::    ::: :::::::::          :::::::: ::::::::::: ::::::::  ::::::::: 
    :+:    :+: :+:       :+:    :+: :+:    :+: :+:+:   :+: :+:    :+:        :+:    :+:    :+:    :+:    :+: :+:    :+: 
   +:+        +:+       +:+        +:+    +:+ :+:+:+  +:+ +:+    +:+        +:+           +:+    +:+    +:+ +:+    +:+  
  +#++:++#++ +#++:++#  +#+        +#+    +:+ +#+ +:+ +#+ +#+    +:+        +#++:++#++    +#+    +#+    +:+ +#++:++#+    
        +#+ +#+       +#+        +#+    +#+ +#+  +#+#+# +#+    +#+               +#+    +#+    +#+    +#+ +#+           
#+#    #+# #+#       #+#    #+# #+#    #+# #+#   #+#+# #+#    #+#        #+#    #+#    #+#    #+#    #+# #+#            
########  ########## ########   ########  ###    #### #########          ########     ###     ########  ###             

****************************************************************************************************
"Remember, you are the dreamer, you build this world."

SSH a level deeper if you dare. This time no password is provided. 
However, you might find the file id_rsa helpful...

Helpful commands: nmap, ssh, ls, get, help

****************************************************************************************************

EOF
)

while read player; do
  player=$(echo -n $player)
  cd /home/$player
  
  echo "$message" > message 
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