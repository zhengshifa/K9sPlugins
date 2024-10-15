#!/bin/bash
export PATH=$PATH:~/.config/k9s/bin

#获取资源的yaml文件

##依赖下面的几个工具
## kubectl-split-yaml  ketall  kubectl-neat

RESOURCE_NAME=$1
NAME=$2
NAMESPACE=$3
CONTEXT=$4
CURR_DATE=${CONTEXT}_${NAME}_$(date +%Y-%m-%d_%H_%M_%S).yaml

if [ "$RESOURCE_NAME" = "namespaces" ]; then
    #获取全部资源yaml
    #
    echo "导出命名空间所有yaml"
    read -p "是否保存yaml文件到本地[y/n]: " SIN
    if [ $SIN == 'y' ]; then
        ketall --context=$CONTEXT --namespace=${NAME}  -oyaml  | kubectl-split-yaml  -p /tmp/${CURR_DATE}
        cd /tmp
        # 遍历目录下的所有 .yaml 文件
        for file in "/tmp/${CURR_DATE}"/*/*.yaml; do
          # 备份原始文件
          mv  "$file" "${file}.bak"
          # 使用 kubectl neat 格式化 YAML 文件并直接重定向输出到原文件
          cat "${file}.bak" | kubectl-neat  > "$file"
          rm -f  "${file}.bak"
        done
        tar -zcf  ${CURR_DATE}.tar.gz  -C ${CURR_DATE} .
        clear   
        rm -rf /tmp/${CURR_DATE}
        echo "sz /tmp/${CURR_DATE}.tar.gz"
        sleep 4
        exit
    else 
       clear
       echo "不保存"
       sleep 1
       exit
    fi
else
    echo "---"
    kubectl get $RESOURCE_NAME  $NAME  -n $NAMESPACE  --context=$CONTEXT -o yaml | kubectl-neat
    echo "---"
    tail -f /dev/null
fi