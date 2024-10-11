#!/bin/bash

export PATH=$PATH:~/.config/k9s/bin

create_role_and_binding() {
  read -p "Enter the namespace [default: default]: " namespace
  namespace=${namespace:-default}

  read -p "Enter the role name [default: my-role]: " role_name
  role_name=${role_name:-my-role}

  echo "Available verbs: get, list, watch, create, update, patch, delete, exec"
  read -p "Enter the verbs [default: "get", "list", "watch"]: " verbs
  verbs=${verbs:-"get", "list", "watch"}

  echo "Available resources: services, endpoints, pods, secrets, configmaps, crontabs, deployments, jobs, nodes, rolebindings, clusterroles, daemonsets, replicasets, statefulsets, horizontalpodautoscalers, replicationcontrollers, cronjobs"
  read -p "Enter the resources [default: pods]: " resources
  resources=${resources:-"pods"}

  echo "Select the apiGroups (space-separated, e.g., \"\" apps):"
  echo "Available apiGroups: \"\", apps, autoscaling, batch"
  read -p "Enter the apiGroups [default: \"\"]: " apiGroups
  apiGroups=${apiGroups:-""}

  cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: $namespace
  name: $role_name
rules:
- apiGroups: ["$apiGroups"]
  resources: [$resources]
  verbs: [$verbs]
EOF

  read -p "Enter the role binding name [default: my-role-binding]: " role_binding_name
  role_binding_name=${role_binding_name:-my-role-binding}

  user_name=$username

  cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: $role_binding_name
  namespace: $namespace
subjects:
- kind: User
  name: $user_name
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: $role_name
  apiGroup: rbac.authorization.k8s.io
EOF


  echo "Role $role_name and RoleBinding $role_binding_name created in namespace $namespace."
}


 add_user() {
  
  read -p "输入新用户名称: " username
  read -p "输入用户组名称: " usergroup
  # 获取当前上下文
  current_context=$(kubectl config current-context)
  # 获取集群名称和服务器地址
  cluster_name=$(kubectl config view -o jsonpath="{.contexts[?(@.name=='${current_context}')].context.cluster}")
  server=$(kubectl config view -o jsonpath="{.clusters[?(@.name=='${cluster_name}')].cluster.server}")

  user_kubeconfig=${cluster_name}_${username}_config
    #CA路径
  #CA=/etc/kubernetes/pki/ca.crt
  #CAKEY=/etc/kubernetes/pki/ca.key

  CA=/var/lib/rancher/k3s/server/tls/server-ca.crt
  CAKEY=/var/lib/rancher/k3s/server/tls/server-ca.key

  # 创建私钥
  openssl genrsa -out ${username}.key 2048
  # 创建证书签名请求
  openssl req -new -key ${username}.key -out ${username}.csr -subj "/CN=${username}/O=${usergroup}"
  # 使用 Kubernetes 集群的 CA 签署证书
  openssl x509 -req -in ${username}.csr -CA ${CA} -CAkey ${CAKEY} -CAcreateserial -out ${username}.crt -days 365
  # 配置 kubectl 使用该证书
  kubectl config set-credentials ${username} --client-certificate=${username}.crt --client-key=${username}.key   --embed-certs=true  --kubeconfig=${user_kubeconfig}
  kubectl config set-context ${username}-context --cluster=kubernetes --namespace=default --user=${username}  --kubeconfig=${user_kubeconfig}
  kubectl config set-cluster ${cluster_name} --server=${server} --certificate-authority=${CA} --embed-certs=true --kubeconfig=${user_kubeconfig}

  # 使用上下文
  kubectl config use-context ${username}-context --kubeconfig=${user_kubeconfig}


  echo "用户 ${username} 已添加"
  #创建绑定
  read -p "1.role创建并绑定 2.clusterrole创建并绑定 3.已有role绑定 4.已有clusterrile绑定: " num
  if [[ $num == 1 ]]; then
    create_role
    create_role_binding
  elif [[ $num == 2 ]] ;then
    create_cluster_role
    create_cluster_role_binding
  elif [[ $num == 3 ]] ;then
    create_role_binding
  else
    create_cluster_role_binding
  fi
}

 delete_user() {
  read -p "输入要删除的用户名: " username
  kubectl config unset users.${username}
  kubectl config unset contexts.${username}-context
  rm -f ${username}.key ${username}.crt ${username}.csr
  echo "用户 ${username} 已删除"
}

 update_user() {
  read -p "输入要更新的用户名: " username
  delete_user ${username}
  add_user
  echo "用户 ${username} 已更新"
}

 list_users() {
  kubectl config get-contexts -o name
}


create_role() {
  read -p "Enter the namespace [default: default]: " namespace
  namespace=${namespace:-default}

  read -p "Enter the role name [default: my-role]: " role_name
  role_name=${role_name:-my-role}

  echo "Available verbs: get, list, watch, create, update, patch, delete, exec"
  read -p "Enter the verbs [default: "get", "list", "watch"]: " verbs
  verbs=${verbs:-"get", "list", "watch"}

  echo "Available resources: services, endpoints, pods, secrets, configmaps, crontabs, deployments, jobs, nodes, rolebindings, clusterroles, daemonsets, replicasets, statefulsets, horizontalpodautoscalers, replicationcontrollers, cronjobs"
  read -p "Enter the resources [default: pods]: " resources
  resources=${resources:-"pods"}

  echo "Select the apiGroups (space-separated, e.g., \"\" apps):"
  echo "Available apiGroups: \"\", apps, autoscaling, batch"
  read -p "Enter the apiGroups [default: \"\"]: " apiGroups
  apiGroups=${apiGroups:-""}

  cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: $namespace
  name: $role_name
rules:
- apiGroups: ["$apiGroups"]
  resources: [$resources]
  verbs: [$verbs]
EOF

  echo "Role $role_name created in namespace $namespace."
}

delete_role() {
  read -p "Enter the namespace [default: default]: " namespace
  namespace=${namespace:-default}

  read -p "Enter the role name: " role_name

  kubectl delete role $role_name -n $namespace
  echo "Role $role_name deleted from namespace $namespace."
}

update_role() {
  delete_role
  create_role
  echo "Role updated."
}

list_roles() {
  read -p "Enter the namespace [default: default]: " namespace
  namespace=${namespace:-default}

  kubectl get roles -n $namespace
}

create_cluster_role() {
  read -p "Enter the cluster role name [default: my-cluster-role]: " cluster_role_name
  cluster_role_name=${cluster_role_name:-my-cluster-role}

  echo "Available verbs: get, list, watch, create, update, patch, delete, exec"
  read -p "Enter the verbs [default: "get", "list", "watch"]: " verbs
  verbs=${verbs:-"get", "list", "watch"}

  echo "Available resources: services, endpoints, pods, secrets, configmaps, crontabs, deployments, jobs, nodes, rolebindings, clusterroles, daemonsets, replicasets, statefulsets, horizontalpodautoscalers, replicationcontrollers, cronjobs"
  read -p "Enter the resources [default: pods]: " resources
  resources=${resources:-"pods"}

  echo "Select the apiGroups (space-separated, e.g., \"\" apps):"
  echo "Available apiGroups: \"\", apps, autoscaling, batch"
  read -p "Enter the apiGroups [default: \"\"]: " apiGroups
  apiGroups=${apiGroups:-""}

  cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: $cluster_role_name
rules:
- apiGroups: ["$apiGroups"]
  resources: [$resources]
  verbs: [$verbs]
EOF

  echo "ClusterRole $cluster_role_name created."
}

delete_cluster_role() {
  read -p "Enter the cluster role name: " cluster_role_name

  kubectl delete clusterrole $cluster_role_name
  echo "ClusterRole $cluster_role_name deleted."
}

update_cluster_role() {
  delete_cluster_role
  create_cluster_role
  echo "ClusterRole updated."
}

list_cluster_roles() {
  kubectl get clusterroles
}

create_role_binding() {
  read -p "Enter the namespace [default: default]: " namespace
  namespace=${namespace:-default}

  read -p "Enter the role binding name [default: my-role-binding]: " role_binding_name
  role_binding_name=${role_binding_name:-my-role-binding}

  read -p "Enter the role name: " role_name
  read -p "Enter the username: " username

  cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: $role_binding_name
  namespace: $namespace
subjects:
- kind: User
  name: $username
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: $role_name
  apiGroup: rbac.authorization.k8s.io
EOF

  echo "RoleBinding $role_binding_name created in namespace $namespace."
}

delete_role_binding() {
  read -p "Enter the namespace [default: default]: " namespace
  namespace=${namespace:-default}

  read -p "Enter the role binding name: " role_binding_name

  kubectl delete rolebinding $role_binding_name -n $namespace
  echo "RoleBinding $role_binding_name deleted from namespace $namespace."
}

update_role_binding() {
  delete_role_binding
  create_role_binding
  echo "RoleBinding updated."
}

list_role_bindings() {
  read -p "Enter the namespace [default: default]: " namespace
  namespace=${namespace:-default}

  kubectl get rolebindings -n $namespace
}

create_cluster_role_binding() {
  read -p "Enter the cluster role binding name [default: my-cluster-role-binding]: " cluster_role_binding_name
  cluster_role_binding_name=${cluster_role_binding_name:-my-cluster-role-binding}

  read -p "Enter the cluster role name: " cluster_role_name
  read -p "Enter the username: " username

  cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: $cluster_role_binding_name
subjects:
- kind: User
  name: $username
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: $cluster_role_name
  apiGroup: rbac.authorization.k8s.io
EOF

  echo "ClusterRoleBinding $cluster_role_binding_name created."
}

delete_cluster_role_binding() {
  read -p "Enter the cluster role binding name: " cluster_role_binding_name

  kubectl delete clusterrolebinding $cluster_role_binding_name
  echo "ClusterRoleBinding $cluster_role_binding_name deleted."
}

update_cluster_role_binding() {
  delete_cluster_role_binding
  create_cluster_role_binding
  echo "ClusterRoleBinding updated."
}

list_cluster_role_bindings() {
  kubectl get clusterrolebindings
}

while true; do
  echo "Kubernetes RBAC Management"
  echo "1. Add User"
  echo "2. Delete User"
  echo "3. Update User"
  echo "4. List Users"
  echo "5. Create Role"
  echo "6. Delete Role"
  echo "7. Update Role"
  echo "8. List Roles"
  echo "9. Create ClusterRole"
  echo "10. Delete ClusterRole"
  echo "11. Update ClusterRole"
  echo "12. List ClusterRoles"
  echo "13. Create RoleBinding"
  echo "14. Delete RoleBinding"
  echo "15. Update RoleBinding"
  echo "16. List RoleBindings"
  echo "17. Create ClusterRoleBinding"
  echo "18. Delete ClusterRoleBinding"
  echo "19. Update ClusterRoleBinding"
  echo "20. List ClusterRoleBindings"
  echo "21. Exit"
  read -p "Choose an option: " option

  case $option in
    1) add_user ;;
    2) delete_user ;;
    3) update_user ;;
    4) list_users ;;
    5) create_role ;;
    6) delete_role ;;
    7) update_role ;;
    8) list_roles ;;
    9) create_cluster_role ;;
    10) delete_cluster_role ;;
    11) update_cluster_role ;;
    12) list_cluster_roles ;;
    13) create_role_binding ;;
    14) delete_role_binding ;;
    15) update_role_binding ;;
    16) list_role_bindings ;;
    17) create_cluster_role_binding ;;
    18) delete_cluster_role_binding ;;
    19) update_cluster_role_binding ;;
    20) list_cluster_role_bindings ;;
    21) exit 0 ;;
    *) echo "Unknown option: $option" ;;
  esac
done
