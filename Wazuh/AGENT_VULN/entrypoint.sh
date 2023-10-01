#!/bin/bash

export WAZUH_MANAGER=$JOIN_MANAGER
export WAZUH_AGENT_NAME=$NAME

apt-get install -y wazuh-agent
/var/ossec/bin/wazuh-control start

python3 -m flask run --host=0.0.0.0
