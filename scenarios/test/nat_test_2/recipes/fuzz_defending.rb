remote_file "start_defense_server" do
  source "https://raw.githubusercontent.com/clampz/fuzzy_challenge/master/src/start_defense_server"
  path "/usr/bin/start_defense_server"
  mode "0765"
  not_if "test -e /tmp/test-file"
end

remote_file "equal" do
  source "https://raw.githubusercontent.com/clampz/fuzzy_challenge/master/src/equal.py"
  path "/usr/bin/equal"
  mode "0765"
  not_if "test -e /tmp/test-file"
end

remote_file "doubles_s_and_r" do
  source "https://raw.githubusercontent.com/clampz/fuzzy_challenge/master/src/doubles_s_and_r"
  path "/usr/bin/doubles_s_and_r"
  mode "0765"
  not_if "test -e /tmp/test-file"
end

remote_file "fuzzing_rules" do
  source "https://raw.githubusercontent.com/clampz/fuzzy_challenge/master/src/cat_motd"
  path "/usr/bin/fuzzing_rules"
  mode "0765"
  not_if "test -e /tmp/test-file"
end

remote_file "defending_server_reboot" do
  source "https://raw.githubusercontent.com/clampz/fuzzy_challenge/master/src/nc_server_reboot"
  path "/usr/bin/defending_server_reboot"
  mode "0765"
  not_if "test -e /tmp/test-file"
end

remote_file "blacklist_replace" do
  source "https://raw.githubusercontent.com/clampz/fuzzy_challenge/master/src/blacklist_replace.py"
  path "/usr/bin/blacklist_replace"
  mode "0765"
  not_if "test -e /tmp/test-file"
end

remote_file "update_calc" do
  source "https://raw.githubusercontent.com/clampz/fuzzy_challenge/master/src/update_calc"
  path "/usr/bin/update_calc"
  mode "0765"
  not_if "test -e /tmp/test-file"
end

remote_file "defender_motd" do
  source "http://ada.evergreen.edu/~weidav02/defender_motd.txt"
  path "/etc/motd.tail"
  not_if "test -e /tmp/test-file"
end

remote_file "get_attacker_input" do
  source "https://raw.githubusercontent.com/clampz/fuzzy_challenge/master/src/get_attacker_input"
  path "/usr/bin/get_attacker_input"
  mode "0765"
  not_if "test -e /tmp/test-file"
end

remote_file "submit_calc" do
  source "https://raw.githubusercontent.com/clampz/fuzzy_challenge/master/src/submit_calc"
  path "/usr/bin/submit_calc"
  mode "0765"
  not_if "test -e /tmp/test-file"
end

script "start_defending_env" do
  interpreter "bash"
  cwd "/etc/update-motd.d"
  code <<-EOH
  echo "start_defense_server" >> /usr/bin/defending_server_reboot
  echo "" > /etc/legal
  rm 10* 50* 51* 90* 91* 98*
  touch /tmp/test-file
  EOH
  not_if "test -e /tmp/test-file"
end