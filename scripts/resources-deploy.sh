#!/bin/bash
export PATH=$PATH:~/.config/k9s/bin

##实现简单部署pod/deploy/sts资源

NAMESPACE=$1
CONTEXT=$2

# Function to create Pod YAML
create_pod() {
  cat <<EOF > /tmp/${META_NAME}.yaml
apiVersion: v1
kind: Pod
metadata:
  name: $META_NAME
  namespace: $NAMESPACE
  labels:
    app: $META_NAME
spec:
  containers:
  - name: $META_NAME-container
    image: $IMAGE
    ports:
    - containerPort: 80
    command: ["/bin/sh", "-c"]
    args: ["tail -f /dev/null"]
EOF
  echo "Pod YAML has been created in ${META_NAME}.yaml"
}

# Function to create Deployment YAML
create_deployment() {
  cat <<EOF > /tmp/${META_NAME}.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $META_NAME
  namespace: $NAMESPACE  
  labels:
    app: $META_NAME
spec:
  replicas: 3
  selector:
    matchLabels:
      app: $META_NAME
  template:
    metadata:
      labels:
        app: $META_NAME
    spec:
      containers:
      - name: $META_NAME-container
        image: $IMAGE
        ports:
        - containerPort: 80
        command: ["/bin/sh", "-c"]
        args: ["tail -f /dev/null"]
EOF
  echo "Deployment YAML has been created in ${META_NAME}.yaml"
}

# Function to create StatefulSet YAML
create_statefulset() {
  cat <<EOF > /tmp/${META_NAME}.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: $META_NAME
  namespace: $NAMESPACE  
  labels:
    app: $META_NAME
spec:
  serviceName: "$META_NAME-service"
  replicas: 3
  selector:
    matchLabels:
      app: $META_NAME
  template:
    metadata:
      labels:
        app: $META_NAME
    spec:
      containers:
      - name: $META_NAME-container
        image: $IMAGE
        ports:
        - containerPort: 80
        command: ["/bin/sh", "-c"]
        args: ["tail -f /dev/null"]
#  volumeClaimTemplates:
#  - metadata:
#      name: $META_NAME-pvc
#    spec:
#      accessModes: [ "ReadWriteOnce" ]
#      resources:
#        requests:
#          storage: 1Gi
EOF
  echo "StatefulSet YAML has been created in ${META_NAME}.yaml"
}

# Function to create DaemonSet YAML
create_daemonset() {
  cat <<EOF > /tmp/${META_NAME}.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: $META_NAME
  namespace: $NAMESPACE
  labels:
    app: $META_NAME
spec:
  selector:
    matchLabels:
      app: $META_NAME
  template:
    metadata:
      labels:
        app: $META_NAME
    spec:
      containers:
      - name: $META_NAME-container
        image: $IMAGE
        ports:
        - containerPort: 80
        command: ["/bin/sh", "-c"]
        args: ["tail -f /dev/null"]
EOF
  echo "DaemonSet YAML has been created in ${META_NAME}.yaml"
}


# Prompt the user to choose the resource type
echo "Select the resource type to create:"
echo "1. Pod"
echo "2. Deployment"
echo "3. StatefulSet"
echo "4. DaemonSet"
read -p "Enter your choice (1/2/3/4): " CHOICE

# Create the corresponding YAML file based on user choice and apply it
case $CHOICE in
  1)
    read -p "Enter the image name (e.g., nginx:latest): " IMAGE
    read -p "Enter the resource name: " META_NAME  
    create_pod
    ;;
  2)
    read -p "Enter the image name (e.g., nginx:latest): " IMAGE
    read -p "Enter the resource name: " META_NAME    
    create_deployment
    ;;
  3)
    read -p "Enter the image name (e.g., nginx:latest): " IMAGE
    read -p "Enter the resource name: " META_NAME    
    create_statefulset
    ;;
  4)
    read -p "Enter the image name (e.g., nginx:latest): " IMAGE
    read -p "Enter the resource name: " META_NAME    
    create_daemonset
    ;;
  *)
    echo "Invalid choice"
    exit 1
    ;;
esac

# Apply the generated YAML file
kubectl apply -f /tmp/${META_NAME}.yaml --context=${CONTEXT}

if [ $? -eq 0 ]; then
  echo "${META_NAME} has been successfully created."
else
  echo "Failed to create ${META_NAME}. Please check the YAML file and try again."
fi
rm -rf /tmp/${META_NAME}.yaml
read -p "按任意退出: "