#!/bin/bash
source <(cat $(git rev-parse --show-toplevel)/.env)

keyfile=~/.ssh/id_rsa

rg=`az group list --query "[?starts_with(name,'$AZURE_ENV_NAME')].name" -o tsv`

fqdn=`az network public-ip list -g $rg --query "[?starts_with(name,'vm-corp-dns')].dnsSettings.fqdn" -o tsv`

user=`az vm list -g $rg --query "[?starts_with(name,'vm-corp-dns')].osProfile.adminUsername" -o tsv`

ssh-keygen -R $fqdn

ssh -i $keyfile $user@$fqdn
