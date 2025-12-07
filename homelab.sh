#!/bin/bash

source .venv/bin/activate
tofu apply --auto-approve

pip install -r requirements.txt
ansible-galaxy install -r requirements.yml

ansible-playbook ./playbooks/playbook.yml
