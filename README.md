# k9s guide

## 项目概述
K9sPlugins 是一个为 k9s Kubernetes CLI 工具提供增强功能的插件集合。它包含:
- 自定义插件:通过 plugins.yaml 定义
- 实用脚本:位于 scripts 目录下
- 二进制工具:位于 bin 目录下

## 官方地址
https://github.com/derailed/k9s
https://k9scli.io/

## 配置文件位置
Config:            ~/.config/k9s/config.yaml
Custom Views:      ~/.config/k9s/views.yaml  
Plugins:           ~/.config/k9s/plugins.yaml
Hotkeys:           ~/.config/k9s/hotkeys.yaml
Aliases:           ~/.config/k9s/aliases.yaml
Skins:             ~/.config/k9s/skins
Context Configs:   ~/.local/share/k9s/clusters
Logs:              ~/.local/state/k9s/k9s.log
Benchmarks:        ~/.local/state/k9s/benchmarks
ScreenDumps:       ~/.local/state/k9s/screen-dumps
scripts:           ~/.config/k9s/scripts/
bin:               ~/.config/k9s/bin/

## 插件说明
plugins.yaml 中定义了以下常用插件:
- duplicate-pod: 复制Pod配置
- file-up-down: 文件上传下载
- get-depen: 获取资源依赖关系
- get-yaml: 获取资源YAML
- kftray: Kube Forwarder管理
- kor: 查找未使用资源
- kptop: 资源使用率监控
- logtail: 日志跟踪
- middleware-cli: 中间件管理
- modify-secret: 修改Secret
- pexec: Pod内执行命令
- ptcpdump: Pod网络抓包
- rbac-ac: RBAC权限检查
- rbac-user: 用户权限管理
- resources-deploy: 资源部署
- rollout-deploy: 滚动更新管理

## 安装设置
```bash
# 创建必要目录
mkdir -p ~/.config/k9s/scripts/
mkdir -p ~/.config/k9s/bin/

# 复制配置文件
cp plugins.yaml ~/.config/k9s/
cp scripts/*.sh ~/.config/k9s/scripts/

# 下载二进制工具
wget -O- https://github.com/Telemaco019/duplik8s/releases/download/v0.2.1/duplik8s_Linux_x86_64.tar.gz | tar -xz -C ~/.config/k9s/bin/
wget -O- https://github.com/tohjustin/kube-lineage/releases/download/v0.5.0/kube-lineage_linux_amd64.tar.gz | tar -xz -C ~/.config/k9s/bin/
wget -O- https://github.com/nathforge/kubectl-split-yaml/releases/download/v0.1.0/kubectl-split-yaml_0.1.0_linux_amd64.tar.gz | tar -xz -C ~/.config/k9s/bin/
wget -O- https://github.com/corneliusweig/ketall/releases/download/v1.3.8/get-all-amd64-linux.tar.gz | tar -xz -C ~/.config/k9s/bin/  | mv ~/.config/k9s/bin/get-all-amd64-linux ~/.config/k9s/bin/ketall
wget -O- https://github.com/itaysk/kubectl-neat/releases/download/v2.0.4/kubectl-neat_linux_amd64.tar.gz | tar -xz -C ~/.config/k9s/bin/ 
wget -O- https://github.com/yonahd/kor/releases/download/v0.5.5/kor_Linux_x86_64.tar.gz | tar -xz -C ~/.config/k9s/bin/
wget -O- https://github.com/rajatjindal/kubectl-modify-secret/releases/download/v0.0.47/kubectl-modify-secret_v0.0.47_linux_amd64.tar.gz | tar -xz -C ~/.config/k9s/bin/
wget -O- https://github.com/hcavarsan/kftray/releases/download/v0.14.9/kftui_linux_amd64 | tar xz -C ~/.config/k9s/bin
wget -O /tmp/kubectl-browse-pvc-linux.zip https://github.com/clbx/kubectl-browse-pvc/releases/download/v1.0.7/kubectl-browse-pvc-linux.zip && unzip /tmp/kubectl-browse-pvc-linux.zip -d ~/.config/k9s/bin && rm -rf /tmp/kubectl-browse-pvc-linux.zip
wget -O /tmp/kube-prompt_v1.0.11_linux_amd64.zip https://github.com/c-bata/kube-prompt/releases/download/v1.0.11/kube-prompt_v1.0.11_linux_amd64.zip && unzip /tmp/kube-prompt_v1.0.11_linux_amd64.zip -d ~/.config/k9s/bin && rm -rf /tmp/kube-prompt_v1.0.11_linux_amd64.zip

https://github.com/knight42/kubectl-blame/releases/download/v0.0.12/kubectl-blame-v0.0.12-linux-amd64.tar.gz 
https://github.com/control-theory/gonzo/releases/download/v0.3.0/gonzo-0.3.0-linux-amd64.tar.gz


# 设置执行权限
chmod +x ~/.config/k9s/scripts/*
chmod +x ~/.config/k9s/bin/*
```

## 使用指南
1. 启动k9s:
   ```bash
   k9s
   ```

2. 使用插件:
   - 按 `:` 进入命令模式
   - 输入插件名称,如 `duplicate-pod`
   - 按提示操作

3. 常用快捷键:
   - `d`:描述资源
   - `e`:编辑资源
   - `l`:查看日志
   - `s`:进入Shell
   - `/`:搜索资源
