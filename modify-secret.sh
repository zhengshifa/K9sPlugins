#!/bin/bash
export PATH=$PATH:~/.config/k9s/bin

##直接读取secret密文并支持修改


##依赖下面的工具
#https://github.com/rajatjindal/kubectl-modify-secret.git

NAMESPACE=$1
RESOURCE_NAME=$2
CONTEXT=$3
NAME=$4

kubectl modify-secret $NAME -n $NAMESPACE --context=$CONTEXT