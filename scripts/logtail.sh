#!/bin/bash
export PATH=$PATH:~/.config/k9s/bin

###查看倒数N行日志或者保存日志

# 定义kubectl命令行参数
KUBECTL_ARGS="--namespace=$1"

# 定义pod和container名称
POD_NAME="$2"
CONTAINER_NAME="$3"
CONTEXT="$4"

clear
# 计算给定分钟前的时间点
read -p "请输入要查询多少分钟的日志: " MINUTES
LOG_TIME=$(date -d "-$MINUTES minutes" --utc +"%Y-%m-%dT%H:%M:%SZ")
log_file="/tmp/$1_$2_$3_$(date +%Y-%m-%d_%H_%M_%S).log"


# 获取指定pod指定container中指定时间点之后的日志
kubectl logs $KUBECTL_ARGS $POD_NAME -c $CONTAINER_NAME --context=$CONTEXT --since-time=$LOG_TIME |tee "$log_file"
echo -e "\n\n\n\n\n\n\n"

let log_size=$(stat -c%s  "$log_file")/1024/1024
read -p "是否保存日志[y/n]: " SIN


if [ $SIN == 'y' ]; then

    if [ $log_size -ge 10 ];then

        clear
        echo "sz ${log_file%.*}.tar.gz"
        tar -zcvf ${log_file%.*}.tar.gz ${log_file}

    else
        clear   
        echo "sz $log_file"
        sleep 3
    fi

else 
   clear
   echo "不保存"
   rm -f "$log_file"
   sleep 1
   exit
fi