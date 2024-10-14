#!/bin/bash
export PATH=$PATH:~/.config/k9s/bin

##各种中间件客户端,用于一次性手动测试任务


NAMESPACE=$1
CONTEXT=$2

# 定义容器镜像映射
declare -A images
images=(
  ["netshoot"]="nicolaka/netshoot"
  ["redis7-4"]="docker.m.daocloud.io/library/redis:7.4.0-alpine3.20"
  ["redis6-2-14"]="docker.m.daocloud.io/library/redis:6.2.14-alpine3.20"
  ["postgresql"]="chinamobile.com/zsf/postgresql-client:latest"
  ["rabbitmq3-9"]="docker.m.daocloud.io/library/rabbitmq:3.9-alpine"
  ["rabbitmq3-13-6"]="docker.m.daocloud.io/library/rabbitmq:3.13.6-management-alpine"
  ["mysql8-0-39"]="docker.m.daocloud.io/library/mysql:8.0.39"
  ["mysql5-7-44"]="docker.m.daocloud.io/library/mysql:5.7.44"
  ["kafka3-8-0"]="docker.m.daocloud.io/bitnami/kafka:3.8.0"
  ["minio-cli"]="docker.m.daocloud.io/jumpserver/mc"
  ["mongodb"]="docker.m.daocloud.io/library/mongo:latest"
  ["rocketmq"]="apache/rocketmq:latest"
  ["Memcached"]="docker.m.daocloud.io/library/memcached:latest"
  ["ES"]="docker.m.daocloud.io/library/elasticsearch:7.17.23"
)


# 生成服务选项列表
options=("${!images[@]}")

# 显示菜单
echo "请选择要部署的服务:"
select service in "${options[@]}"; do
  if [[ -n "${images[$service]}" ]]; then
    pod_name="${service}-pod"
    image_name="${images[$service]}"
    echo "正在部署 $service..."
    kubectl run --rm -it  -n ${NAMESPACE}  --context=${CONTEXT} "$pod_name" --image="$image_name" --restart=Never -- sh
    break
  else
    echo "无效选项，请重新选择。"
  fi
done