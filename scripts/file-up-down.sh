#!/bin/bash
export PATH=$PATH:~/.config/k9s/bin

##k8s pod容器文件上传和下载

namespace=$2
pod=$1
container=$3
CONTEXT=$4

# 提示用户选择上传或下载
echo "Do you want to upload a file to a pod or download a file from a pod?"
select operation in "Upload" "Download"; do
  case $operation in
    Upload )
      # 获取当前目录的文件列表
      files=(./*)

      # 显示文件列表并提示用户选择
      echo "Select a file to upload to the pod:"
      select file in "${files[@]}"; do
        # 检查用户是否选择了一个有效的文件
        if [[ -n $file ]]; then
          echo "You selected the file: $file"
          break
        else
          echo "Invalid selection. Please try again."
        fi
      done
      break;;
    Download )
      # 提示用户输入 Pod 中的目标目录
      read -p "Enter the path of the directory in the pod: " pod_dir_path
      # 获取 Pod 中的文件列表
      pod_files=($(kubectl exec $1 -n $2 -c $3 --context=$CONTEXT  -- ls "$pod_dir_path"))
      # 显示文件列表并提示用户选择
      echo "Select a file to download from the pod:"
      select pod_file_path in "${pod_files[@]}"; do
        # 检查用户是否选择了一个有效的文件
        if [[ -n $pod_file_path ]]; then
          echo "You selected the file: $pod_file_path"
          break
        else
          echo "Invalid selection. Please try again."
        fi
      done
      break;;
    * )
      echo "Invalid selection. Please try again."
      ;;
  esac
done

# 提示用户输入 Pod 中的目标路径或本地的目标路径
if [[ $operation == "Upload" ]]; then
  read -p "Enter the target path in the pod: " target
  # 使用 kubectl cp 命令来复制文件到 Pod
  kubectl cp "$file" "$namespace/$pod:$target" -c $container --context=$CONTEXT
elif [[ $operation == "Download" ]]; then
  read -p "Enter the target path on your local machine: " local_target_path
  # 使用 kubectl cp 命令来下载文件
  kubectl cp "$namespace/$pod:$pod_dir_path/$pod_file_path" "$local_target_path" -c $container --context=$CONTEXT

fi