#!/bin/bash

set -e

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

rg=`az group list  --query "[?starts_with(name,'$AZURE_ENV_NAME')].name" -o tsv`
hubcontainer=`az container list -g $rg  --query "[?starts_with(name,'hub-jump')].name" -o tsv`
spokecontainer=`az container list -g $rg  --query "[?starts_with(name,'spoke-jump')].name" -o tsv`
az container stop -g $rg -n $hubcontainer
az container stop -g $rg -n $spokecontainer
