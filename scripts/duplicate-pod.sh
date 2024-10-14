#!/bin/bash

export PATH=$PATH:~/.config/k9s/bin

#复制deploy/pod
##依赖这个工具
#https://github.com/Telemaco019/duplik8s/releases/download/v0.2.1/duplik8s_Linux_x86_64.tar.gz
#
NAMESPACE=$1
CONTEXT=$3
NAME=$4

if [ $2 == deployments ];then
    RESOURCE_NAME=deploy
else 
    RESOURCE_NAME=pod
fi

kubectl duplicate $RESOURCE_NAME $NAME -n $NAMESPACE --context $CONTEXT