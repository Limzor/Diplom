#/bin/bash
ansible-playbook -i hosts.ini --private-key=~/.ssh/bastionkey -u ubuntu Bastion.yml
ansible-playbook -i inventory.ini --private-key=~/.ssh/bastionkey -u ubuntu playbook.yml