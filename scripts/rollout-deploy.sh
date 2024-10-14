#!/bin/bash
export PATH=$PATH:~/.config/k9s/bin

## 回滚  deploy镜像版本

deployment_name=$1
NAMESPACE=$2
CONTEXT=$3
echo "xxxxxxxxxxx当前Deployment的版本:xxxxxxxxxx"
kubectl get deploy $deployment_name --namespace=$NAMESPACE  --context=$CONTEXT -o jsonpath='版本号:{.metadata.annotations.deployment\.kubernetes\.io/revision}' ;echo ""
kubectl get deploy $deployment_name --namespace=$NAMESPACE --context=$CONTEXT  -o jsonpath='镜像版本:{.spec.template.spec.containers[*].image}'  ;echo ""
echo ""
echo ""
echo ""
# 显示Deployment的历史版本
echo "xxxxxxxxx显示Deployment的历史版本:xxxxxxxxxx"
replicasets=$(kubectl get replicaset --namespace=$NAMESPACE -o jsonpath='{.items[*].metadata.name}' --context=$CONTEXT)
for rs in $replicasets; do
    if [[ $rs == $deployment_name* ]]; then
        kubectl get replicaset $rs --namespace=$NAMESPACE -o jsonpath='版本号:{.metadata.annotations.deployment\.kubernetes\.io/revision}' --context=$CONTEXT  ;echo ""
        kubectl get replicaset $rs --namespace=$NAMESPACE -o jsonpath='创建时间:{.metadata.creationTimestamp}' --context=$CONTEXT  ;echo ""
        kubectl get replicaset $rs --namespace=$NAMESPACE -o jsonpath='镜像版本:{.spec.template.spec.containers[*].image}' --context=$CONTEXT ;echo ""
        echo "-------------"
    fi
done
echo ""
echo ""
# 获取用户输入的版本号
echo "xxxxxxxxxx请输入你想要回滚到的版本号:xxxxxxxxxxx"
read revision_number

# 回滚到指定版本
echo "正在回滚到版本$revision_number..."
kubectl rollout undo deployment/$deployment_name --to-revision=$revision_number  -n  $NAMESPACE --context=$CONTEXT

read -p "按任意退出: "