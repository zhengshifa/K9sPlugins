#!/bin/bash
export PATH=$PATH:~/.config/k9s/bin

## rbac 绑定主体为ac

# Function to create a role and bind it
create_role_and_binding() {
  read -p "Enter the namespace [default: default]: " namespace
  namespace=${namespace:-default}

  read -p "Enter the role name [default: my-role]: " role_name
  role_name=${role_name:-my-role}

  echo "Available verbs: get, list, watch, create, update, patch, delete, exec"
  read -p "Enter the verbs [default: get]: " verbs
  verbs=${verbs:-"get"}

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

  read -p "Enter the user to bind [default: default-user]: " user_name
  user_name=${user_name:-default-user}

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

# Function to view roles in a namespace
view_roles_and_binding() {
  read -p "Enter the namespace [default: all]: " namespace
  namespace=${namespace:-all}
  if [ "$namespace" = "all" ]; then
    echo "---------> Roles:"
    kubectl get roles -A
    echo "###########"
    echo "---------> RoleBindings:"
    kubectl get RoleBinding -A
    echo "###########"
  else
    echo "---------> Roles:"
    kubectl get roles -n "$namespace"
    echo "###########"
    echo "---------> RoleBindings:"
    kubectl get RoleBinding -n "$namespace"
    echo "###########"
  fi
}

# Function to delete a role
delete_role() {
  read -p "Enter the namespace [default: default]: " namespace
  namespace=${namespace:-default}
  read -p "Enter the role name [default: my-role]: " role_name
  role_name=${role_name:-my-role}
  kubectl delete role $role_name -n $namespace
  echo "Role $role_name deleted in namespace $namespace."
}

# Function to delete a role binding
delete_role_binding() {
  read -p "Enter the namespace [default: default]: " namespace
  namespace=${namespace:-default}
  read -p "Enter the role binding name [default: my-role-binding]: " role_binding_name
  role_binding_name=${role_binding_name:-my-role-binding}
  kubectl delete rolebinding $role_binding_name -n $namespace
  echo "RoleBinding $role_binding_name deleted in namespace $namespace."
}


####集群角色管理
create_cluster_role_and_binding() {
  read -p "Enter cluster role name: " cluster_role_name
  read -p "Enter cluster role binding name: " cluster_role_binding_name
  read -p "Enter service account name (namespace/name): " sa_name
  read -p "Enter policy rules (in JSON format): " policy_rules
  
  cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: $cluster_role_name
rules: $policy_rules
EOF

  namespace=$(echo $sa_name | cut -d'/' -f1)
  sa=$(echo $sa_name | cut -d'/' -f2)

  cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: $cluster_role_binding_name
subjects:
- kind: ServiceAccount
  name: $sa
  namespace: $namespace
roleRef:
  kind: ClusterRole
  name: $cluster_role_name
  apiGroup: rbac.authorization.k8s.io
EOF

  echo "Cluster Role and Cluster Role Binding created successfully."
}

view_cluster_roles_and_bindings() {
  read -p "Enter the namespace [default: all]: " namespace
  namespace=${namespace:-all}
  
  if [ "$namespace" = "all" ]; then
    echo "---------> ClusterRoles:"
    kubectl get clusterroles -A
    echo "###########"
    echo "---------> ClusterRoleBindings:"
    kubectl get clusterrolebindings -A 
    echo "###########"
  else
    echo "---------> ClusterRoles:"
    kubectl get clusterroles -n "$namespace"
    echo "###########"
    echo "---------> ClusterRoleBindings:"
    kubectl get clusterrolebindings -n "$namespace"
    echo "###########"
  fi
}




delete_cluster_role() {
  read -p "Enter cluster role name: " cluster_role_name
  kubectl delete clusterrole $cluster_role_name
}

delete_cluster_role_binding() {
  read -p "Enter cluster role binding name: " cluster_role_binding_name
  kubectl delete clusterrolebinding $cluster_role_binding_name
}

# Menu
while true; do
  echo "Kubernetes RBAC Management"
  echo "1. Create a Role and Role Binding"
  echo "2. View Roles and Bindings"
  echo "3. Delete a Role"
  echo "4. Delete a Role Binding"
  echo "5. Create a Cluster Role and Cluster Role Binding"
  echo "6. View Cluster Roles and Bindings"
  echo "7. Delete a Cluster Role"
  echo "8. Delete a Cluster Role Binding"
  echo "9. Exit"
  read -p "Choose an option: " option

  case $option in
    1)
      create_role_and_binding
      ;;
    2)
      view_roles_and_binding
      ;;
    3)
      delete_role
      ;;
    4)
      delete_role_binding
      ;;
    5)
      create_cluster_role_and_binding
      ;;
    6)
      view_cluster_roles_and_bindings
      ;;
    7)
      delete_cluster_role
      ;;
    8)
      delete_cluster_role_binding
      ;;
    9)
      exit 0
      ;;
    *)
      echo "Invalid option. Please choose again."
      ;;
  esac
done