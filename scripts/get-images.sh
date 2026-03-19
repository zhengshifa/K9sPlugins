#!/bin/bash

export PATH=$PATH:~/.config/k9s/bin

kubectl get pods -n "$1" --context $2 -o jsonpath="{.items[*].spec.containers[*].image}" | tr ' ' '\n' | sort | uniq


read -p "按任意退出: "