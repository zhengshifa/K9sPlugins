# k9s guide

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

## 设置
mkdir -p        ~/.config/k9s/scripts/
mkdir -p        ~/.config/k9s/bin/
cp plugins.yaml  ~/.config/k9s/
cp *.sh         ~/.config/k9s/scripts/


wget -O  ~/.config/k9s/bin/duplik8s              https://github.com/Telemaco019/duplik8s/releases/download/v0.2.1/duplik8s_Linux_x86_64.tar.gz
wget -O  ~/.config/k9s/bin/kube-lineage          https://github.com/tohjustin/kube-lineage/releases/download/v0.5.0/kube-lineage_linux_amd64.tar.gz
wget -O  ~/.config/k9s/bin/kubectl-split-yaml    https://github.com/nathforge/kubectl-split-yaml/releases/download/v0.1.0/kubectl-split-yaml_0.1.0_linux_amd64.tar.gz
wget -O  ~/.config/k9s/bin/ketall                https://github.com/corneliusweig/ketall/releases/download/v1.3.8/get-all-amd64-linux.tar.gz
wget -O  ~/.config/k9s/bin/kubectl-neat          https://github.com/itaysk/kubectl-neat/releases/download/v2.0.4/kubectl-neat_linux_amd64.tar.gz
wget -O  ~/.config/k9s/bin/kor                   https://github.com/yonahd/kor/releases/download/v0.5.5/kor_Linux_x86_64.tar.gz
wget -O  ~/.config/k9s/bin/kubectl-modify-secret https://github.com/rajatjindal/kubectl-modify-secret/releases/download/v0.0.47/kubectl-modify-secret_v0.0.47_linux_amd64.tar.gz

https://github.com/eslam-gomaa/kptop
https://github.com/hcavarsan/kftray

chmod +x ~/.config/k9s/scripts/*
chmod +x ~/.config/k9s/bin/*