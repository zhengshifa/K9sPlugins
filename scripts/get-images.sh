#!/bin/bash
# 获取命名空间下所有容器的镜像名称
# 用法: ./get-images.sh <namespace> <context> [format]
# format: simple (默认) | detail | csv

NAMESPACE=$1
CONTEXT=$2
FORMAT=${3:-simple}

if [ -z "$NAMESPACE" ] || [ -z "$CONTEXT" ]; then
    echo "用法: $0 <namespace> <context> [format]"
    echo "format: simple (默认) | detail | csv"
    exit 1
fi

case $FORMAT in
    simple)
        echo "=== $NAMESPACE 命名空间镜像列表 ==="
        kubectl get pods -n "$NAMESPACE" --context "$CONTEXT" \
            -o jsonpath='{range .items[*]}{.spec.containers[*].image}{"\n"}{end}' \
            | tr ' ' '\n' | sort | uniq
        ;;
    detail)
        echo "=== $NAMESPACE 命名空间容器镜像详情 ==="
        kubectl get pods -n "$NAMESPACE" --context "$CONTEXT" \
            -o jsonpath='{range .items[*]}{"Pod: "}{.metadata.name}{"\n"}{range .spec.containers[*]}{"  容器: "}{.name}{" -> 镜像: "}{.image}{"\n"}{end}{end}'
        ;;
    csv)
        kubectl get pods -n "$NAMESPACE" --context "$CONTEXT" \
            -o jsonpath='{range .items[*]}{.metadata.name}{","}{range .spec.containers[*]}{.name}{","}{.image}{"\n"}{end}{end}' \
            | sed 's/,/\t/g'
        ;;
    *)
        echo "不支持的格式: $FORMAT"
        exit 1
        ;;
esac

echo ""
echo "按任意键退出..."
read -n 1 -s
