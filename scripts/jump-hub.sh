#!/bin/bash

set -e

source <(cat $(git rev-parse --show-toplevel)/.env)

rg=`az group list  --query "[?starts_with(name,'$AZURE_ENV_NAME')].name" -o tsv`
hubcontainer=`az container list -g $rg  --query "[?starts_with(name,'hub-jump')].name" -o tsv`
az container start -g $rg -n $hubcontainer
az container exec -g $rg -n $hubcontainer --exec-command "/bin/bash"
