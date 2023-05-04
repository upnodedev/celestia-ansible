#!/bin/bash

echo "Welcome to the Celestia deployment script by Upnode!"
echo ""

echo "Please enter information about your deployment"

read -p "SSH IP Address or Host: " ssh_host
read -p "SSH Port (22): " ssh_port
ssh_port="${ssh_port:-22}"
read -p "SSH Username: " ssh_username
read -p "Login with private key (y/n): " ssh_use_pk

if [[ "$ssh_use_pk" == "y" || "$ssh_use_pk" == "Y" ]]; then
  read -p "SSH Key File Path: " ssh_pk
elif [[ "$ssh_use_pk" == "n" || "$ssh_use_pk" == "N" ]]; then
  read -p "SSH Password: " ssh_password
else
  echo "Invalid input. Please enter y or n."
  exit
fi

cat << EOF > inventory.ini
[blockspacerace]
blockspacerace-node ansible_host=$ssh_host type=main prepare=true

[mocha]
mocha-node ansible_host=$ssh_host type=main prepare=true

[all:vars]
ansible_user=$ssh_username
ansible_password=$ssh_password
ansible_port=$ssh_port
$( [[ "$ssh_use_pk" == "y" || "$ssh_use_pk" == "Y" ]] && echo ";" )ansible_ssh_private_key_file="$ssh_pk"

var_file="group_vars/testnets/{{ group_names[0] }}.yml"
user_dir="/home/{{ansible_user}}"
path="/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/bin:/usr/local/go/bin:{{ user_dir }}/go/bin"
node_exporter=true
promtail=false
log_monitor=https://XXXXXX:XXXXXXXXXXXXXXXXXXXX=@logs-prod-011.grafana.net/api/prom/push
log_name="PREFIX_{{ network }}_{{ type }}"
node_name=upnode.org
EOF

echo ""
echo "Successfully write inventory.ini file"

echo "Which chain you want to deploy?"
echo "1. blockspacerace"
echo "2. mocha"

read -p "Enter the number of your choice: " chain_name_number

case $chain_name_number in
  1) chain_name="blockspacerace";;
  2) chain_name="mocha";;
esac

echo ""

echo "Which type of node you want to deploy?"
echo "1. Validator node"
echo "2. Bridge, Full or Light node"

read -p "Enter the number of your choice: " node_type_number

echo ""

# validate the user's input
case $node_type_number in
  1)
    ansible-playbook main.yml -e "target=$chain_name-node" $( [[ "$ssh_use_pk" == "n" || "$ssh_use_pk" == "N" ]] && echo "--ask-become-pass" )
    echo "Neccessary softwares have been setup. Next, you must import your validator key or create a new validator on your own for security reason."
    ;;
  2)
    echo "Which type of node you want to deploy?"
    echo "1. Bridge Node"
    echo "2. Full Node"
    echo "3. Light Node"

    read -p "Enter the number of your choice: " node_sub_type_number

    echo ""

    case $node_sub_type_number in
      1) node_sub_type="bridge";;
      2) node_sub_type="full";;
      3) node_sub_type="light";;
      *) echo "Invalid choice.";;
    esac

    ansible-playbook celestia_node.yml -e "target=$chain_name-node celestia_node_type=$node_sub_type" $( [[ "$ssh_use_pk" == "n" || "$ssh_use_pk" == "N" ]] && echo "--ask-become-pass" )
    ;;
  *)
    echo "Invalid choice."
    ;;
esac