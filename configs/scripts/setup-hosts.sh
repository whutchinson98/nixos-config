#!/bin/sh

# Redis nodes for docker redis cluster
sudo tee -a /etc/hosts << EOF
127.0.0.1 redis-node-0
127.0.0.1 redis-node-1
127.0.0.1 redis-node-2
127.0.0.1 redis-node-3
127.0.0.1 redis-node-4
127.0.0.1 redis-node-5
EOF
