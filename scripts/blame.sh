#!/bin/bash

export PATH=$PATH:~/.config/k9s/bin

RESOURCE_NAME=$1
NAME=$2
NAMESPACE=$3
CONTEXT=$4

kubectl-blame $RESOURCE_NAME $NAME -n $NAMESPACE --context $CONTEXT
read -p "按任意退出: "