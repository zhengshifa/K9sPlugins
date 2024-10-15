#!/bin/bash
export PATH=$PATH:~/.config/k9s/bin

##查看资源的所有依赖关系

##依赖工具
#https://github.com/tohjustin/kube-lineage.git

NAMESPACE=$1
RESOURCE_NAME=$2
CONTEXT=$3
NAME=$4

if [ $RESOURCE_NAME == 'pods' ];then
    kubectl-lineage  $RESOURCE_NAME  $NAME  --dependencies  -n $NAMESPACE  --context=$CONTEXT 


    # 获取 pod 的标签并转换为 key=value 格式
    labels=$(kubectl get $RESOURCE_NAME  $NAME  -n $NAMESPACE  --context=$CONTEXT  -o jsonpath='{.metadata.labels}' | sed 's/[{}"]//g' | awk -v RS=',' '{gsub(/:/,"="); print}')

    # 使用 while 循环遍历每一行
    echo "$labels" | while IFS= read -r line; do
        SVC=kubectl get  $RESOURCE_NAME -n $NAMESPACE  --context=$CONTEXT  -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.selector}{"\n"}{end}' | sed 's/":"/=/g' | grep $line |awk '{print $1}'
        kubectl-lineage  svc $SVC  --output=split --show-group -n $NAMESPACE  --context=$CONTEXT 
    done
elif [[ $RESOURCE_NAME == 'configmaps' || $RESOURCE_NAME == 'deployments' || $RESOURCE_NAME == 'cronjobs' || $RESOURCE_NAME == 'role' || $RESOURCE_NAME == 'statefulsets' || $RESOURCE_NAME == 'daemonsets' ]];then
    kubectl-lineage  $RESOURCE_NAME  $NAME  --output=split --show-group -n $NAMESPACE  --context=$CONTEXT
elif [[ $RESOURCE_NAME == 'clusterrolebindings' || $RESOURCE_NAME == 'clusterroles' ]];then
    kubectl-lineage  $RESOURCE_NAME  $NAME  --output=split --show-group  --context=$CONTEXT
else
    kubectl-lineage  $RESOURCE_NAME  $NAME  --dependencies  -n $NAMESPACE  --context=$CONTEXT 
fi

read -p "按任意退出: "