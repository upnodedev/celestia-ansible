#!/bin/bash

echo "Welcome to the Celestia deployment script by Upnode!"
echo ""

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
    ansible-playbook main.yml -e "target=$chain_name" --ask-become-pass
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

    ansible-playbook celestia_node.yml -e "target=$chain_name celestia_node_type=$node_sub_type" --ask-become-pass
    ;;
  *)
    echo "Invalid choice."
    ;;
esac