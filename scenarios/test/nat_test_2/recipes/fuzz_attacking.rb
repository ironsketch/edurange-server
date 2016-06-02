remote_file "start_attack_server" do
  source "https://raw.githubusercontent.com/clampz/fuzzy_challenge/master/src/start_attack_server"
  path "/usr/bin/start_attack_server"
  mode "0765"
  not_if "test -e /tmp/test-file"
end

remote_file "send_fuzz_data" do
  source "https://raw.githubusercontent.com/clampz/fuzzy_challenge/master/src/send_fuzz_data"
  path "/usr/bin/send_fuzz_data"
  mode "0765"
  not_if "test -e /tmp/test-file"
end

remote_file "attacking_server_reboot" do
  source "https://raw.githubusercontent.com/clampz/fuzzy_challenge/master/src/nc_server_reboot"
  path "/usr/bin/attacking_server_reboot"
  mode "0765"
  not_if "test -e /tmp/test-file"
end

remote_file "fuzzing_rules" do
  source "https://raw.githubusercontent.com/clampz/fuzzy_challenge/master/src/cat_motd"
  path "/usr/bin/fuzzing_rules"
  mode "0765"
  not_if "test -e /tmp/test-file"
end

remote_file "attacker_motd" do
  source "http://ada.evergreen.edu/~weidav02/attacker_motd.txt"
  path "/etc/motd.tail"
  not_if "test -e /tmp/test-file"
end

script "start_attacking_env" do
  interpreter "bash"
  cwd "/etc/update-motd.d"
  code <<-EOH
  echo "start_attack_server" >> /usr/bin/attacking_server_reboot
  start_attack_server &
  echo "" > /etc/legal
  rm 10* 50* 51* 90* 91* 98*
  touch /tmp/test-file
  EOH
  not_if "test -e /tmp/test-file"
end