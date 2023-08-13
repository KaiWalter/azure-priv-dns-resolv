#!/bin/bash
source <(cat $(git rev-parse --show-toplevel)/.env)

keyfile=~/.ssh/id_rsa
user=vmadmin
timestamp=`date +"%s"`

az deployment sub create -f infra/main.bicep -n main-infra-$timestamp \
  -l $AZURE_LOCATION \
  -p name=$AZURE_ENV_NAME \
  location=$AZURE_LOCATION \
  adminUsername=$user \
  adminPasswordOrKey="$(cat $keyfile.pub)" \
  vmCustomData="$(cat infra/corp-dns-cloud-init.txt)"
