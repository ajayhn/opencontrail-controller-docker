#!/bin/bash
export hostname=$(hostname) && sed -i "s/NODENAME=.*/NODENAME=$hostname/" /etc/rabbitmq/rabbitmq-env.conf
