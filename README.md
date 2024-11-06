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



wget -O- https://gh.con.sh/https://github.com/Telemaco019/duplik8s/releases/download/v0.2.1/duplik8s_Linux_x86_64.tar.gz               |tar -xz -C   ~/.config/k9s/bin/          
wget -O- https://gh.con.sh/https://github.com/tohjustin/kube-lineage/releases/download/v0.5.0/kube-lineage_linux_amd64.tar.gz               |tar -xz -C   ~/.config/k9s/bin/     
wget -O- https://gh.con.sh/https://github.com/nathforge/kubectl-split-yaml/releases/download/v0.1.0/kubectl-split-yaml_0.1.0_linux_amd64.tar.gz               |tar -xz -C   ~/.config/k9s/bin/  
wget -O- https://gh.con.sh/https://github.com/corneliusweig/ketall/releases/download/v1.3.8/get-all-amd64-linux.tar.gz               |tar -xz -C   ~/.config/k9s/bin/         
wget -O- https://gh.con.sh/https://github.com/itaysk/kubectl-neat/releases/download/v2.0.4/kubectl-neat_linux_amd64.tar.gz               |tar -xz -C   ~/.config/k9s/bin/     
wget -O- https://gh.con.sh/https://github.com/yonahd/kor/releases/download/v0.5.5/kor_Linux_x86_64.tar.gz               |tar -xz -C   ~/.config/k9s/bin/                 
wget -O- https://gh.con.sh/https://github.com/rajatjindal/kubectl-modify-secret/releases/download/v0.0.47/kubectl-modify-secret_v0.0.47_linux_amd64.tar.gz               |tar -xz -C   ~/.config/k9s/bin/
#wget -O  ~/.config/k9s/bin/kptop   https://github.com/eslam-gomaa/kptop
wget -O- https://gh.con.sh/https://github.com/hcavarsan/kftray/releases/download/v0.14.9/kftui_linux_amd64  |tar xz -C ~/.config/k9s/bin
wget -O- https://gh.con.sh/https://github.com/tohjustin/kube-lineage/releases/download/v0.5.0/kube-lineage_linux_amd64.tar.gz  |tar xz -C ~/.config/k9s/bin
wget -O /tmp/kube-prompt_v1.0.11_linux_amd64.zip https://github.com/c-bata/kube-prompt/releases/download/v1.0.11/kube-prompt_v1.0.11_linux_amd64.zip && unzip /tmp/kube-prompt_v1.0.11_linux_amd64.zip -d ~/.config/k9s/bin && rm -rf /tmp/kube-prompt_v1.0.11_linux_amd64.zip

chmod +x ~/.config/k9s/scripts/*
chmod +x ~/.config/k9s/bin/*