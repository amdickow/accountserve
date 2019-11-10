#!/bin/bash
# Will run forever...
external_ip=""
while [ -z $external_ip ]; do
  echo "Waiting for deployment..." >&2
  external_ip=$(kubectl get service/$1 --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
  [ -z "$external_ip" ] && sleep 10
done
echo 'Deployment ready:' >&2 && 
echo $external_ip