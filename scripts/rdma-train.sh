#!/bin/bash
export PATH=$PATH:~/.config/k9s/bin

## 基于 N 节点模板启动多机 RDMA 训练任务
## pod-1 为主节点 (NODE_RANK=0, master_addr 由 ipoib IP 指定)
## pod-2..pod-N 为从节点 (NODE_RANK=1..N-1)
##
## 用法: 用户输入 training command 模板, 用 __NODE_RANK__ 占位 node rank
##       脚本自动按 pod 顺序把 __NODE_RANK__ 替换为 0, 1, 2, ...
## 示例: bash /mnt/nfs-models/run_short.sh __NODE_RANK__
##
## 节点选择: 输入节点数 N, 默认从节点池前 N 个; 也可手动指定逗号分隔 hostname

NAMESPACE=$1
CONTEXT=$2

# 默认配置
DEFAULT_JOB_PREFIX="rdma-gpu-test"
DEFAULT_NUM_NODES=2
DEFAULT_IMAGE="easzlab.io.local:30500/modelscope-repo/modelscope:ubuntu22.04-cuda13.0.3-py312-torch2.11.0-vllm0.21.0-modelscope1.36.3-swift4.2.3"
DEFAULT_MASTER_ADDR="100.99.0.10"
DEFAULT_MASTER_PORT="29500"

# 默认节点池（按 IP 降序，108 优先, 与之前 2 节点配置向后兼容）
DEFAULT_NODE_POOL="a100-9-108 a100-9-107 a100-9-106 a100-9-105 a100-9-104 a100-9-103 a100-9-102 a100-9-101"

# NFS / 共享内存
NFS_SERVER="192.168.9.120"
NFS_PATH="/mnt/models"
DSHM_SIZE="4Gi"

# ---- 输入 ----
read -p "Enter job name prefix [$DEFAULT_JOB_PREFIX]: " JOB_PREFIX
JOB_PREFIX=${JOB_PREFIX:-$DEFAULT_JOB_PREFIX}
JOB_NAME="${JOB_PREFIX}-$(date +%Y%m%d-%H%M%S)"

# 节点数
read -p "Enter number of training nodes [$DEFAULT_NUM_NODES]: " NUM_NODES
NUM_NODES=${NUM_NODES:-$DEFAULT_NUM_NODES}
if ! [[ "$NUM_NODES" =~ ^[0-9]+$ ]] || [ "$NUM_NODES" -lt 1 ]; then
    echo "Invalid number of nodes: '$NUM_NODES'"
    read -p "按任意键退出："
    exit 1
fi

# 节点列表
read -p "Use default node pool? (y/n) [y]: " USE_DEFAULT
USE_DEFAULT=${USE_DEFAULT:-y}

if [ "$USE_DEFAULT" = "y" ] || [ "$USE_DEFAULT" = "Y" ]; then
    POOL_ARR=($DEFAULT_NODE_POOL)
    if [ "$NUM_NODES" -gt "${#POOL_ARR[@]}" ]; then
        echo "Not enough nodes in default pool (have ${#POOL_ARR[@]}, need $NUM_NODES)."
        read -p "按任意键退出："
        exit 1
    fi
    NODES=("${POOL_ARR[@]:0:$NUM_NODES}")
    echo "Selected nodes: ${NODES[*]}"
else
    read -p "Enter $NUM_NODES hostnames (comma-separated): " NODES_INPUT
    IFS=',' read -ra NODES <<< "$NODES_INPUT"
    # trim whitespace
    for i in "${!NODES[@]}"; do
        NODES[$i]=$(echo "${NODES[$i]}" | xargs)
    done
    if [ "${#NODES[@]}" -ne "$NUM_NODES" ]; then
        echo "Expected $NUM_NODES hostnames, got ${#NODES[@]}: ${NODES[*]}"
        read -p "按任意键退出："
        exit 1
    fi
    echo "Selected nodes: ${NODES[*]}"
fi

read -p "Enter image [$DEFAULT_IMAGE]: " IMAGE
IMAGE=${IMAGE:-$DEFAULT_IMAGE}

read -p "Enter master_addr (pod-1 IPOIB IP) [$DEFAULT_MASTER_ADDR]: " MASTER_ADDR
MASTER_ADDR=${MASTER_ADDR:-$DEFAULT_MASTER_ADDR}

read -p "Enter master_port [$DEFAULT_MASTER_PORT]: " MASTER_PORT
MASTER_PORT=${MASTER_PORT:-$DEFAULT_MASTER_PORT}

echo ""
echo "Enter training command (use __NODE_RANK__ as rank placeholder, empty line to finish):"
echo "(e.g. bash /mnt/nfs-models/run_short.sh __NODE_RANK__)"
CMD_INPUT=""
while true; do
  IFS= read -r line
  if [ -z "$line" ]; then
    break
  fi
  stripped="${line#"${line%%[![:space:]]*}"}"
  CMD_INPUT="${CMD_INPUT}
            ${stripped}"
done
CMD_INPUT="${CMD_INPUT#"${CMD_INPUT%%[![:space:]]*}"}"

if [ -z "$CMD_INPUT" ]; then
    echo "Command cannot be empty."
    read -p "按任意键退出："
    exit 1
fi

# ---- 生成 YAML ----
YAML_FILE="/tmp/${JOB_NAME}.yaml"
: > $YAML_FILE

for i in "${!NODES[@]}"; do
    RANK=$i
    POD_NAME="${JOB_NAME}-pod-$((i+1))"
    NODE_HOST=${NODES[$i]}

    # 替换 NODE_RANK 占位符
    POD_CMD=$(echo "$CMD_INPUT" | sed "s/__NODE_RANK__/${RANK}/g")

    # pod-1 需要固定 IP annotation, 其他用简单 annotation
    if [ "$i" -eq 0 ]; then
        ANNOTATION="  annotations:
    k8s.v1.cni.cncf.io/networks: |
      [
        {
          \"name\": \"example-ipoibnetwork\",
          \"ips\": \"[${MASTER_ADDR}]\"
        }
      ]"
    else
        ANNOTATION="  annotations:
    k8s.v1.cni.cncf.io/networks: example-ipoibnetwork"
    fi

    # 第一个之前不加 ---
    if [ "$i" -gt 0 ]; then
        echo "---" >> $YAML_FILE
    fi

    cat <<POD_YAML >> $YAML_FILE
apiVersion: v1
kind: Pod
metadata:
  name: ${POD_NAME}
${ANNOTATION}
spec:
  nodeSelector:
    kubernetes.io/hostname: ${NODE_HOST}
  restartPolicy: OnFailure
  containers:
  - image: ${IMAGE}
    name: ${POD_NAME}-ctr
    command: ["/bin/bash", "-c"]
    args:
    - |
      ${POD_CMD}
    securityContext:
      capabilities:
        add: [ "IPC_LOCK" ]
    resources:
      limits:
        nvidia.com/gpu: 8
        rdma/rdma_shared_device_a: 1
      requests:
        nvidia.com/gpu: 8
        rdma/rdma_shared_device_a: 1
    volumeMounts:
    - name: dshm
      mountPath: /dev/shm
    - name: nfs-model-storage
      mountPath: /mnt/nfs-models
  volumes:
  - name: dshm
    emptyDir:
      medium: Memory
      sizeLimit: ${DSHM_SIZE}
  - name: nfs-model-storage
    nfs:
      server: ${NFS_SERVER}
      path: ${NFS_PATH}
POD_YAML
done

echo ""
echo "===== Generated YAML (${NUM_NODES} pods) ====="
cat $YAML_FILE
echo "============================================="
echo ""

read -p "Apply this job? (y/n) [y]: " APPLY
APPLY=${APPLY:-y}

if [ "$APPLY" = "y" ] || [ "$APPLY" = "Y" ]; then
    kubectl apply -f $YAML_FILE --context=${CONTEXT} -n ${NAMESPACE}
    if [ $? -eq 0 ]; then
        echo "${NUM_NODES} pods have been created under job '${JOB_NAME}'."
    else
        echo "Failed to create pods. YAML saved at $YAML_FILE"
        read -p "按任意键退出："
        exit 1
    fi
else
    echo "Pods not applied. YAML saved at $YAML_FILE"
fi

rm -f $YAML_FILE
read -p "按任意键退出："
