#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

DOMAIN=""
V2PATH=""
V2PORT=0
USERID=""

# 安装软件
function softInstall(){
    # 安装 curl
    apt-get -y install curl
    # 安装 unzip
    apt-get -y install unzip
    # 安装 acme.sh 依赖
    apt-get -y install socat

    # 安装 acme.sh
    curl https://get.acme.sh | sh
    ~/.acme.sh/acme.sh --upgrade --auto-upgrade

    # 安装 V2Ray
    bash <(curl -L -s https://install.direct/go.sh)
    
    mkdir /usr/local/caddy
    mkdir /usr/local/caddy/cert
    mkdir /usr/local/caddy/frontPage

    # 安装 Caddy
    cd "/usr/local/caddy"
    wget --no-check-certificate -O "caddy_linux64.tar.gz" "https://caddyserver.com/download/linux/amd64?plugins=http.filemanager&license=personal"
    tar zxf "caddy_linux64.tar.gz"
    rm -rf LICENSES.txt README.txt CHANGES.txt init EULA.txt 1> /dev/null
    chmod +x caddy
    wget --no-check-certificate -O "caddy.serv" "https://raw.githubusercontent.com/rawSpace/Files/master/caddy.serv"
    mv caddy.serv /etc/init.d/caddy
    chmod +x /etc/init.d/caddy
    update-rc.d -f caddy defaults
    
    # 安装 Web
    cd "/usr/local/caddy/frontPage"
    wget --no-check-certificate -O "frontPage.zip" "https://github.com/rawSpace/Files/raw/master/frontPage.zip"
    unzip frontPage.zip
}

# 设置V2Ray配置文件
function setV2RayConfig(){
    wget --no-check-certificate -O "/etc/v2ray/config.json" "https://raw.githubusercontent.com/rawSpace/Files/master/wsTLSweb.json"
    sed -i "s/【UUID】/${USERID}/g" "/etc/v2ray/config.json"
    sed -i "s/【端口】/${V2PORT}/g" "/etc/v2ray/config.json"
    sed -i "s/【路径】/${V2PATH}/g" "/etc/v2ray/config.json"
}

# 设置caddy配置文件
function setCaddyfile(){
    wget --no-check-certificate -O "/usr/local/caddy/Caddyfile" "https://raw.githubusercontent.com/rawSpace/Files/master/Caddyfile"
    sed -i "s/【域名】/${DOMAIN}/g" "/usr/local/caddy/Caddyfile"
    sed -i "s/【端口】/${V2PORT}/g" "/usr/local/caddy/Caddyfile"
    sed -i "s/【路径】/${V2PATH}/g" "/usr/local/caddy/Caddyfile"
}

# 申请证书
function getCert(){
    ~/.acme.sh/acme.sh --issue --standalone -d ${DOMAIN} -k ec-256 --force
    ~/.acme.sh/acme.sh --installcert -d ${DOMAIN}                             \
                       --fullchainpath /usr/local/caddy/cert/${DOMAIN}.crt    \
                       --keypath /usr/local/caddy/cert/${DOMAIN}.key --ecc    \
                       --reloadcmd "service caddy restart"
}

# 启动软件
function softRun(){
    service caddy restart
    sleep 2s
    service v2ray restart
}

# 参数：域名 端口 路径
function main(){
    # 安装软件
    softInstall
    if [[ $? == 0 ]]; then
        echo -e "安装成功！"
    else
        echo -e "安装失败！"
        exit 1
    fi

    # 申请证书
    getCert
    if [[ $? == 0 ]]; then
        echo -e "证书申请成功！"
    else
        echo -e "证书申请失败！"
        exit 1
    fi

    # 设置caddy配置文件
    setCaddyfile
    if [[ $? == 0 ]]; then
        echo -e "设置 Caddyfile 成功！"
    else
        echo -e "设置 Caddyfile 失败！"
        exit 1
    fi

    # 设置V2Ray配置文件
    setV2RayConfig
    if [[ $? == 0 ]]; then
        echo -e "设置 V2Ray Config 成功！"
        echo -e "USERID:${USERID}, alterId:64"
    else
        echo -e "设置 V2Ray Config 失败！"
        exit 1
    fi

    # 启动软件
    softRun
    if [[ $? == 0 ]]; then
        echo -e "启动成功！"
    else
        echo -e "启动失败！"
        exit 1
    fi
}

if [[ $# != 2 ]]; then
    echo -e "参数错误！格式：$0 域名 路径"
    exit 1
fi

DOMAIN=$1
V2PATH=$2
USERID=$(cat /proc/sys/kernel/random/uuid)
V2PORT=`expr $RANDOM + 20000`

main