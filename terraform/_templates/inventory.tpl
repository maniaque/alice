${host}

[all:vars]
ansible_user = ${user}
ansible_ssh_extra_args='-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
ansible_python_interpreter=/usr/bin/python3