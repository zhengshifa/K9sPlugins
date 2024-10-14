#!/bin/bash
export PATH=$PATH:~/.config/k9s/bin

## 批量执行DaemonSet /StatefulSet资源的pod命令


NAMESPACE=$1
RESOURCE_NAME=$2
CONTEXT=$3
NAME=$4

# 交互式输入要执行的命令
read -p "Enter the command to execute in pods:" COMMAND

# 获取该 DaemonSet /StatefulSet 的标签选择器
LABEL_JSON=$(kubectl get $RESOURCE_NAME $NAME -n $NAMESPACE  --context=$CONTEXT  -o jsonpath='{.spec.selector.matchLabels}')

#转换成xxx=xxx格式
LABEL_SELECTOR=$(echo $LABEL_JSON | sed 's/[{}]//g' | sed 's/\"//g' | sed 's/:/=/g' | sed 's/,/ /g' | awk '{$1=$1; print}')

# 获取所有属于该 DaemonSet /StatefulSet 的 Pod
POD_NAMES=$(kubectl get pods -n $NAMESPACE -l "$LABEL_SELECTOR" --context=$CONTEXT -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n')


# 迭代所有 Pod 并执行命令
for POD in $POD_NAMES; do
    echo "Executing command in pod: $POD"
    kubectl exec -n $NAMESPACE $POD --context=$CONTEXT  -- /bin/bash -c "timeout 5 $COMMAND"
    echo -e '\n\n'
    sleep 2
done

read -p "按任意退出: "