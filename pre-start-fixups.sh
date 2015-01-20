#!/bin/bash
export hostname=$(hostname) && sed -i "s/NODENAME=.*/NODENAME=$hostname/" /etc/rabbitmq/rabbitmq-env.conf
export HOST_ADDR=$(ip route get 8.8.8.8 | awk '/8.8.8.8/ {print $NF}') && sed -i "s/listen_address: .*$/listen_address: $HOST_ADDR/" /etc/cassandra/cassandra.yaml 
export HOST_ADDR=$(ip route get 8.8.8.8 | awk '/8.8.8.8/ {print $NF}') && sed -i "s/rpc_address: .*$/rpc_address: $HOST_ADDR/" /etc/cassandra/cassandra.yaml 
export HOST_ADDR=$(ip route get 8.8.8.8 | awk '/8.8.8.8/ {print $NF}') && openstack-config --set /etc/contrail/contrail-discovery.conf DEFAULTS cassandra_server_list $HOST_ADDR:9160
export HOST_ADDR=$(ip route get 8.8.8.8 | awk '/8.8.8.8/ {print $NF}') && openstack-config --set /etc/contrail/contrail-api.conf DEFAULTS cassandra_server_list $HOST_ADDR:9160
export HOST_ADDR=$(ip route get 8.8.8.8 | awk '/8.8.8.8/ {print $NF}') && openstack-config --set /etc/contrail/contrail-schema.conf DEFAULTS cassandra_server_list $HOST_ADDR:9160
export HOST_ADDR=$(ip route get 8.8.8.8 | awk '/8.8.8.8/ {print $NF}') && openstack-config --set /etc/contrail/contrail-svc-monitor.conf DEFAULTS cassandra_server_list $HOST_ADDR:9160
