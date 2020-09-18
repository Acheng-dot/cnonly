#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#fonts color
Green="\033[32m"
Red="\033[31m"
# Yellow="\033[33m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"

#notification information
# Info="${Green}[信息]${Font}"
OK="${Green}[OK]${Font}"
Error="${Red}[错误]${Font}"
source '/etc/os-release'
VERSION=$(echo "${VERSION}" | awk -F "[()]" '{print $2}')

xitong(){
    if [[ "${ID}" == "centos" && ${VERSION_ID} -ge 7 ]]; then
        echo -e "${OK} ${GreenBG} 当前系统为 Centos ${VERSION_ID} ${VERSION} ${Font}"
        INS="yum"
    elif [[ "${ID}" == "debian" && ${VERSION_ID} -ge 8 ]]; then
        echo -e "${OK} ${GreenBG} 当前系统为 Debian ${VERSION_ID} ${VERSION} ${Font}"
        INS="apt"
        $INS update
	   $INS install ipset -y
    elif [[ "${ID}" == "ubuntu" && $(echo "${VERSION_ID}" | cut -d '.' -f1) -ge 16 ]]; then
        echo -e "${OK} ${GreenBG} 当前系统为 Ubuntu ${VERSION_ID} ${UBUNTU_CODENAME} ${Font}"
        INS="apt"
        $INS update
	   $INS install ipset -y
    else
        echo -e "${Error} ${RedBG} 当前系统为 ${ID} ${VERSION_ID} 不在支持的系统列表内，安装中断 ${Font}"
        exit 1
    fi

    if [ $INS=yum ]; then
    systemctl stop firewalld
    systemctl disable firewalld
    echo -e "${OK} ${GreenBG} firewalld 已关闭 ${Font}"
    else 
    systemctl stop ufw
    systemctl disable ufw
    echo -e "${OK} ${GreenBG} ufw 已关闭 ${Font}"
    fi
}

root(){
    if [ 0 == $UID ]; then
        echo -e "${OK} ${GreenBG} 当前用户是root用户，进入安装流程 ${Font}"
        sleep 3
    else
        echo -e "${Error} ${RedBG} 当前用户不是root用户，请切换到root用户后重新执行脚本 ${Font}"
        exit 1
    fi
}


anzhuang(){
    read -rp "请输入连接端口:" port
	wget -O- 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' >/tmp/cn.txt
	if [ -f "/tmp/cn.txt" ]; then
	 echo -e "${OK} ${GreenBG} 中国大陆IP段下载完成 ${Font}"
    else
     echo -e "${RedBG} 下载失败 请检查网络 ${Font}"
    exit 1
    fi
	
	ipset -N cn hash:net
	for i in $(cat /tmp/cn.zone); do ipset -A cn $i; done
	iptables -A INPUT -p tcp --dport ${port} -m set --match-set "cn" src -j ACCEPT
	iptables -A INPUT -p udp --dport ${port} -m set --match-set "cn" src -j ACCEPT
	iptables -A INPUT -p tcp --dport ${port} -j DROP
	iptables -A INPUT -p udp --dport ${port} -j DROP
	echo -e "${OK} ${GreenBG} ipset规则创建完成 ${Font}"
}

cnonly(){
root
xitong
anzhuang
}

cnonly
