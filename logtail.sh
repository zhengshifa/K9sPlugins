#!/bin/bash
export PATH=$PATH:~/.config/k9s/bin

###查看倒数N行日志或者保存日志

# 定义kubectl命令行参数
KUBECTL_ARGS="--namespace=$1"

# 定义pod和container名称
POD_NAME="$2"
CONTAINER_NAME="$3"
CONTEXT="$4"

# 计算给定分钟前的时间点
read -p "请输入要查询多少分钟的日志: " MINUTES
LOG_TIME=$(date -d "-$MINUTES minutes" --utc +"%Y-%m-%dT%H:%M:%SZ")

# 获取指定pod指定container中指定时间点之后的日志
kubectl logs $KUBECTL_ARGS $POD_NAME -c $CONTAINER_NAME --context=$CONTEXT --since-time=$LOG_TIME
echo -e "\n\n\n\n\n\n\n"
read -p "是否保存日志[y/n]: " SIN
if [ $SIN == 'y' ]; then
   kubectl logs $KUBECTL_ARGS $POD_NAME -c $CONTAINER_NAME --context=$CONTEXT --since-time=$LOG_TIME > /tmp/$1_$2_$3_$(date +%Y-%m-%d_%H_%M_%S).log
clear   
echo "sz /tmp/$1_$2_$3_$(date +%Y-%m-%d_%H_%M_%S).log"
sleep 4
else 
   clear
   echo "不保存"
   sleep 1
   exit
fi