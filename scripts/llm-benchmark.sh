#!/bin/bash
export PATH=$PATH:~/.config/k9s/bin

## 基于 job.yaml 模板启动 Job，整个 command 部分由用户自由输入

NAMESPACE=$1
CONTEXT=$2

# 默认值
DEFAULT_JOB_NAME="evalscope-benchmark"
DEFAULT_IMAGE="easzlab.io.local:30500/modelscope-repo/modelscope:ubuntu22.04-py311-torch2.9.1-1.35.0"

# PVC & NFS 配置
PVC_NAME="evalscope-output-pvc"
NFS_SERVER="192.168.9.120"
NFS_PATH="/mnt/models"

# 代理配置
HTTP_PROXY="http://192.168.8.100:17890"
HTTPS_PROXY="http://192.168.8.100:17890"
NO_PROXY="localhost,127.0.0.1,.svc,.cluster.local,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"

# ---- 输入 ----
read -p "Enter job name [$DEFAULT_JOB_NAME]: " JOB_NAME
JOB_NAME=evalscope-benchmark-${JOB_NAME:-$DEFAULT_JOB_NAME}-$(date +%Y%m%d-%H%M%S)

read -p "Enter image [$DEFAULT_IMAGE]: " IMAGE
IMAGE=${IMAGE:-$DEFAULT_IMAGE}

# 整个 command 由用户输入（支持多行，空行结束）
echo ""
echo "Enter command script (empty line to finish):"
echo "(e.g. set -ex; mkdir -p /outputs; evalscope perf --url ... )"
CMD_INPUT=""
while true; do
  IFS= read -r line
  if [ -z "$line" ]; then
    break
  fi
  # 去掉行首空格，统一加 12 个空格缩进（匹配 YAML 结构）
  stripped="${line#"${line%%[![:space:]]*}"}"
  CMD_INPUT="${CMD_INPUT}
            ${stripped}"
done
# 去掉第一行空行（第一次循环产生的前导空行）
CMD_INPUT="${CMD_INPUT#"${CMD_INPUT%%[![:space:]]*}"}"

if [ -z "$CMD_INPUT" ]; then
  echo "Command cannot be empty."
  read -p "按任意键退出："
  exit 1
fi

# ---- 生成 PVC + Job YAML ----
cat <<YAML > /tmp/${JOB_NAME}.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${PVC_NAME}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
---
apiVersion: batch/v1
kind: Job
metadata:
  name: ${JOB_NAME}
  labels:
    app: ${JOB_NAME}
spec:
  backoffLimit: 0
  template:
    metadata:
      labels:
        app: ${JOB_NAME}
    spec:
      restartPolicy: Never
      containers:
      - name: evalscope
        image: ${IMAGE}
        imagePullPolicy: IfNotPresent
        env:
        - name: HTTP_PROXY
          value: "${HTTP_PROXY}"
        - name: HTTPS_PROXY
          value: "${HTTPS_PROXY}"
        - name: NO_PROXY
          value: >-
            ${NO_PROXY}
        command:
          - bash
          - -c
          - |
            ${CMD_INPUT}
        resources:
          requests:
            cpu: "4"
            memory: 8Gi
          limits:
            cpu: "16"
            memory: 32Gi
        volumeMounts:
        - name: outputs
          mountPath: /outputs
        - name: models-data
          mountPath: /root/.cache/modelscope/hub/models
      volumes:
      - name: outputs
        persistentVolumeClaim:
          claimName: ${PVC_NAME}
      - name: models-data
        nfs:
          server: ${NFS_SERVER}
          path: ${NFS_PATH}
      # 可选：固定到压测节点
      # nodeSelector:
      #   kubernetes.io/hostname: a100-8-100
YAML

echo ""
echo "===== Generated YAML ====="
cat /tmp/${JOB_NAME}.yaml
echo "=========================="
echo ""

# 确认是否应用
read -p "Apply this job? (y/n) [y]: " APPLY
APPLY=${APPLY:-y}

if [ "$APPLY" = "y" ]; then
  kubectl apply -f /tmp/${JOB_NAME}.yaml --context=${CONTEXT}
  if [ $? -eq 0 ]; then
    echo "Job '${JOB_NAME}' has been created successfully."
  else
    echo "Failed to create job. Please check the YAML file."
    read -p "按任意键退出："
    exit 1
  fi
else
  echo "Job not applied. YAML saved at /tmp/${JOB_NAME}.yaml"
fi

rm -f /tmp/${JOB_NAME}.yaml
read -p "按任意键退出："
