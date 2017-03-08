script "nat_motd" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
message="\\n################################# NAT #################################\\n\\nWelcome to SSH Inception. The goal is to answer all questions by exploring the local network at 10.0.0.0/27 You are currently at the NAT Instance. Your journey will begin when you login into the host with the following information:\\n\\nIP Address: 10.0.0.5\\n\\nFor every instance you login to you will be greeted with instructions. Each machine will give you a list of useful commands to solve each challenge. Use man pages to help find useful options for commands. For example if the instructions say to use the command 'ssh' entering 'man ssh' will print the man page.\\n\\nThis message is located in your home folder in a file called 'message'.\\n\\n"

while read player; do
  player=$(echo -n $player)
  cd /home/$player
  echo -e $message > message
  chmod 404 message
  echo 'cat message' >> .bashrc
done </root/edurange/players
  EOH
end
