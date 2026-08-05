#!/bin/bash
export PATH=$PATH:~/.config/k9s/bin

##各种中间件客户端,用于一次性手动测试任务
##每个服务配独立的 entrypoint command,不再依赖镜像自带 /bin/sh
##
##菜单中 logs 项是 kubectl logs -f 包装,用来调试已有 pod(类似 tail -f 阻塞跟)
##  - 默认 -f 跟随当前运行的容器
##  - 输入 previous 选 y 时改用 --previous,看 crash 后留下的日志
##  - Ctrl-C 退出
##
##连接参数(中间件):每个服务一行 connection string
##  - postgresql: postgresql://user:password@host:5432/dbname
##  - redis:      redis://:password@host:6379/0
##  - mysql:      mysql://user:password@host:3306/dbname
##  - mongo:      mongodb://user:password@host:27017/dbname?authSource=admin
##  - minio:      http://access_key:secret_key@host:9000   (含 userinfo 的 URL)
##  - rocketmq:   host:9876                                (namesrv 地址,注入为 NAMESRV_ADDR)
##密码仅用于临时调试 pod(--rm 退出即清),生产请走 secret

NAMESPACE=$1
CONTEXT=$2

# 服务名=镜像
# logs 是占位,不走容器部署,在 select 分支单独处理
declare -A images=(
  ["netshoot"]="easzlab.io.local:30500/netshoot:latest"
  ["postgresql"]="easzlab.io.local:30500/postgresql-client:latest"
  ["redis"]="easzlab.io.local:30500/redis:7"
  ["mysql"]="easzlab.io.local:30500/mysql:8.0"
  ["mongo"]="easzlab.io.local:30500/mongo:7"
  ["minio-client"]="easzlab.io.local:30500/minio/mc:RELEASE.2025-08-13T08-35-41Z"
  ["rocketmq"]="easzlab.io.local:30500/apache/rocketmq:5.5.0"
)

# URI/conn 示例(用于 read prompt 提示,用户可粘贴完整字符串)
declare -A uri_examples=(
  ["postgresql"]="postgresql://user:password@host:5432/dbname"
  ["redis"]="redis://:password@host:6379/0"
  ["mysql"]="mysql://user:password@host:3306/dbname"
  ["mongo"]="mongodb://user:password@host:27017/dbname?authSource=admin"
  ["minio-client"]="http://access_key:secret_key@host:9000"
  ["rocketmq"]="host:9876"
)

# 收集容器内要执行的命令(数组形式,避免 URI 内的 : @ / ? 等被 word-split / glob)
# 输出:cmd_args (数组)
build_cmd() {
  local svc=$1 conn
  cmd_args=()
  case "$svc" in
    netshoot)
      cmd_args=("bash")
      ;;
    postgresql)
      read -rp "conn str [${uri_examples[$svc]}]: " conn
      [[ -z "$conn" ]] && return 1
      cmd_args=("$conn")
      ;;
    redis)
      read -rp "conn str [${uri_examples[$svc]}]: " conn
      [[ -z "$conn" ]] && return 1
      cmd_args=("redis-cli" "-u" "$conn")
      ;;
    mysql)
      read -rp "conn str [${uri_examples[$svc]}]: " conn
      [[ -z "$conn" ]] && return 1
      cmd_args=("mysql" "$conn")
      ;;
    mongo)
      read -rp "conn str [${uri_examples[$svc]}]: " conn
      [[ -z "$conn" ]] && return 1
      cmd_args=("mongosh" "$conn")
      ;;
    minio-client)
      # mc alias set 需要拆 host/access/secret;用临时 alias 名 "tmp",容器退出即丢
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
      cmd_args=("mc" "alias" "set" "tmp" "$proto://${host}" "${userinfo%%:*}" "${userinfo##*:}")
      ;;
    rocketmq)
      # 输入 namesrv 地址,启动 mqadmin 子命令;留空则进 sh 交互排查
      read -rp "namesrv addr [${uri_examples[$svc]}]: " conn
      [[ -z "$conn" ]] && return 1
      cmd_args=("mqadmin" "-n" "$conn")
      ;;
  esac
}

# 收集 kubectl logs -f 的参数(数组形式)
# 输出:log_args (数组)
build_log_args() {
  local pod container prev extra=()
  read -rp "pod name: " pod
  if [[ -z "$pod" ]]; then
    echo "pod name 不能为空"
    log_args=()
    return 1
  fi
  read -rp "container (回车跳过): " container
  read -rp "previous (看 crash 日志)? [y/N]: " prev
  [[ -n "$container" ]] && extra=(-c "$container")
  # -f 和 --previous 互斥:follow 要求容器在跑,previous 是已死容器的日志
  if [[ "$prev" =~ ^[Yy]$ ]]; then
    extra+=(--previous)
    log_args=("-n" "${NAMESPACE}" "--context" "${CONTEXT}" "${pod}" "${extra[@]}")
  else
    log_args=("-f" "-n" "${NAMESPACE}" "--context" "${CONTEXT}" "${pod}" "${extra[@]}")
  fi
}

# 生成服务选项列表
options=("${!images[@]}")

# 显示菜单
echo "请选择要执行的操作:"
select service in "${options[@]}"; do
  case "$service" in
    logs)
      if build_log_args && [[ ${#log_args[@]} -gt 0 ]]; then
        echo "tail -f 日志中,Ctrl-C 退出..."
        kubectl logs "${log_args[@]}"
      else
        echo "已取消"
      fi
      break
      ;;
    "")
      echo "无效选项,请重新选择。"
      ;;
    *)
      image_name="${images[$service]}"
      if [[ -n "$image_name" && "$image_name" != "-" ]]; then
        pod_name="${service}-pod"
        if ! build_cmd "$service"; then
          echo "已取消"
          break
        fi
        echo "正在部署 ${service} (image=${image_name})"
        echo "执行: ${cmd_args[*]}"
        # minio-client:mc alias set 跑完后还要继续操作,追加 sh 保活交互;其它服务只用 cmd_args
        if [[ "$service" == "minio-client" ]]; then
          kubectl run --rm -it -n "${NAMESPACE}" --context="${CONTEXT}" "${pod_name}" \
            --image="${image_name}" --restart=Never -- \
            "${cmd_args[@]}" "&&" "sh"
        else
          kubectl run --rm -it -n "${NAMESPACE}" --context="${CONTEXT}" "${pod_name}" \
            --image="${image_name}" --restart=Never -- "${cmd_args[@]}"
        fi
      else
        echo "无效选项,请重新选择。"
      fi
      break
      ;;
  esac
done
