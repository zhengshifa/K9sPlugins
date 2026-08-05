#!/bin/bash
export PATH=$PATH:~/.config/k9s/bin

## 启动中间件客户端容器(--rm 退出即清),用于一次性手动调试
## 每个服务配独立的 entrypoint,不再依赖镜像自带 /bin/sh
##
##连接串直接以 URI/host 形式透传给客户端:
##  - postgresql: postgresql://user:password@host:5432/dbname
##  - redis:      redis://:password@host:6379/0
##  - mysql:      mysql://user:password@host:3306/dbname
##  - mongo:      mongodb://user:password@host:27017/dbname?authSource=admin
##  - minio:      http://access_key:secret_key@host:9000   (含 userinfo 的 URL)
##  - rocketmq:   host:9876                                (namesrv 地址)
##密码仅用于临时调试 pod,生产请走 secret

NAMESPACE=$1
CONTEXT=$2

# 服务名 -> 镜像
declare -A images=(
  ["netshoot"]="easzlab.io.local:30500/netshoot:latest"
  ["postgresql"]="easzlab.io.local:30500/postgresql-client:latest"
  ["redis"]="easzlab.io.local:30500/redis:7"
  ["mysql"]="easzlab.io.local:30500/mysql:8.0"
  ["mongo"]="easzlab.io.local:30500/mongo:7"
  ["minio-client"]="easzlab.io.local:30500/minio/mc:RELEASE.2025-08-13T08-35-41Z"
  ["rocketmq"]="easzlab.io.local:30500/apache/rocketmq:5.5.0"
)

# 连接串示例(用于 read prompt 提示,用户可粘贴完整字符串)
declare -A uri_examples=(
  ["postgresql"]="postgresql://user:password@host:5432/dbname"
  ["redis"]="redis://:password@host:6379/0"
  ["mysql"]="mysql://user:password@host:3306/dbname"
  ["mongo"]="mongodb://user:password@host:27017/dbname?authSource=admin"
  ["minio-client"]="http://access_key:secret_key@host:9000"
  ["rocketmq"]="host:9876"
)

# 收集容器内要执行的命令(数组形式,避免 URI 内的 : @ / ? 等被 word-split / glob)
# 输出全局 cmd
build_cmd() {
  local svc=$1 conn
  cmd=()
  case "$svc" in
    netshoot)
      cmd=(bash)
      ;;
    postgresql)
      read -rp "conn str [${uri_examples[$svc]}]: " conn
      [[ -z "$conn" ]] && return 1
      cmd=(psql "$conn")
      ;;
    redis)
      read -rp "conn str [${uri_examples[$svc]}]: " conn
      [[ -z "$conn" ]] && return 1
      cmd=(redis-cli -u "$conn")
      ;;
    mysql)
      read -rp "conn str [${uri_examples[$svc]}]: " conn
      [[ -z "$conn" ]] && return 1
      cmd=(mysql "$conn")
      ;;
    mongo)
      read -rp "conn str [${uri_examples[$svc]}]: " conn
      [[ -z "$conn" ]] && return 1
      cmd=(mongosh "$conn")
      ;;
    minio-client)
      # mc alias set 需要拆 host/access/secret;用临时 alias 名 "tmp",容器退出即丢
      # 跑完 mc alias set 再追加 sh,继续 ls/cp/rb 等操作
      read -rp "minio URL [${uri_examples[$svc]}]: " conn
      [[ -z "$conn" ]] && return 1
      local proto userinfo host rest
      proto="${conn%%://*}"
      rest="${conn#*://}"
      userinfo="${rest%%@*}"
      host="${rest##*@}"
      # 兼容 https 默认 443、http 默认 9000 端口省略;显式带端口则保留
      if [[ "$host" != *:* ]]; then
        if [[ "$proto" == "https" ]]; then host="${host}:443"; else host="${host}:9000"; fi
      fi
      cmd=(mc alias set tmp "$proto://${host}" "${userinfo%%:*}" "${userinfo##*:}" "&&" sh)
      ;;
    rocketmq)
      read -rp "namesrv addr [${uri_examples[$svc]}]: " conn
      [[ -z "$conn" ]] && return 1
      cmd=(mqadmin -n "$conn")
      ;;
  esac
}

echo "请选择要启动的客户端:"
select service in "${!images[@]}"; do
  if [[ -n "$service" && -n "${images[$service]}" ]]; then
    image_name="${images[$service]}"
    pod_name="${service}-pod"
    if ! build_cmd "$service"; then
      echo "已取消"
      break
    fi
    echo "正在部署 ${service} (image=${image_name})"
    echo "执行: ${cmd[*]}"
    kubectl run --rm -it -n "${NAMESPACE}" --context="${CONTEXT}" "${pod_name}" \
      --image="${image_name}" --restart=Never -- "${cmd[@]}"
    break
  else
    echo "无效选项,请重新选择。"
  fi
done