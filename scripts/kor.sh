#!/bin/bash
export PATH=$PATH:~/.config/k9s/bin

##查看k8s未使用的资源
#依赖 https://github.com/yonahd/kor/releases

NAMESPACE=$1
RESOURCE_NAME=$2
CONTEXT=$3
NAME=$4

if [ $2 == namespaces ];then
    kor clusterrole,configmap,customresourcedefinition,deployment,daemonset,persistentvolume,persistentvolumeclaim,role,secret,serviceaccount,finalizer,StatefulSet,Job   -n $NAMESPACE --show-reason --context $CONTEXT
else 
    kor $RESOURCE_NAME  -n $NAMESPACE --show-reason --context $CONTEXT
fi

read -p "按任意退出: "