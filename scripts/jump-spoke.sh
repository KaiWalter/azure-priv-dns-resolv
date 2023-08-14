#!/bin/bash

set -e

source <(cat $(git rev-parse --show-toplevel)/.env)

rg=`az group list  --query "[?starts_with(name,'$AZURE_ENV_NAME')].name" -o tsv`
spokecontainer=`az container list -g $rg  --query "[?starts_with(name,'spoke-jump')].name" -o tsv`
az container start -g $rg -n $spokecontainer
az container exec -g $rg -n $spokecontainer --exec-command "/bin/bash"
