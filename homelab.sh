#!/bin/bash

source .venv/bin/activate
sudo distrobuilder  build-lxc image.yaml .output -o image.architecture=x86_64 -o image.release=9 -o image.variant=default -o source.variant=boot
tofu apply 

pip install -r requirements.txt
ansible-galaxy install -r requirements.yml

ansible-playbook ./playbooks/playbook.yml
