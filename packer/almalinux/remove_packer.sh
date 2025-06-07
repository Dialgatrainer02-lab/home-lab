#!/bin/bash

USER_TO_REMOVE="packer"

# Check if user exists
if id "$USER_TO_REMOVE" &>/dev/null; then
    echo "Removing user: $USER_TO_REMOVE"
    userdel -r "$USER_TO_REMOVE"
else
    echo "User $USER_TO_REMOVE does not exist. Skipping removal."
fi

# Disable and remove the systemd service
systemctl disable remove-packer.service
rm -f /etc/systemd/system/remove-packer.service
rm -f /opt/remove_packer_once.sh

echo "Cleanup complete. Script will not run again."
