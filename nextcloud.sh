#!/usr/bin/env bash

###########################################
# CentOS 7 NextCloud Install Shell Script #
###########################################

scriptpath=$(pwd)

clear
echo "+-----------------------------------------------------------------------------------------+"
echo "|                         Centos 7 Nextcloud Install Shell Script                         |"
echo "+-----------------------------------------------------------------------------------------+"
echo "|                   A tool to auto-compile & install nextcloud on linux                   |"
echo "+-----------------------------------------------------------------------------------------+"
echo "| This script can install Nextcloud services and 2 office components that can be matched. |"
echo "+-----------------------------------------------------------------------------------------+"

# System check
init_system() {
# Replacement system CentOS-Base repo
cat >/etc/yum.repos.d/CentOS-Base.repo <<"EOF"
# CentOS-Base.repo
# disable metalink enable baseurl
# baseurl default connection address
# http://mirror.centos.org/centos/

[base]
name=CentOS-$releasever - Base
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/os/$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os&infra=$infra
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#released updates 
[updates]
name=CentOS-$releasever - Updates
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/updates/$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=updates&infra=$infra
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras]
name=CentOS-$releasever - Extras
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/extras/$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras&infra=$infra
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-$releasever - Plus
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/centosplus/$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=centosplus&infra=$infra
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF

# check selinux
selinuxstate=$(getenforce)
if [ ${selinuxstate} != "Disabled" ] ; then
	setenforce 0
	echo -e "Permanently shutdown SELINUX function"
	sed -i 's/SELINUX\=enforcing/SELINUX\=disabled/g' /etc/selinux/config
fi
}

# Mysql select version
mysql_config() {
	echo -e "\nMySQL configuration"
	db_info=('MySQL 5.7' 'MySQL 8.0')

	if [ -z ${dbselect} ]; then
		dbselect="1"
		echo "Please select MySQL version."
		echo "1: Install ${db_info[0]} (Default)"
		echo "2: Install ${db_info[1]}"
		read -p "Enter your choice (1 , 2): " dbselect
	fi
	case "${dbselect}" in
	1)
		echo "You will install ${db_info[0]}"
		;;
	2)
		echo "You will install ${db_info[1]}"
		;;
	*)
		echo "No input,You will install ${db_info[0]}"
		dbselect="1"
	esac

	read -p "Please enter the MySQL root Password: " newmysqlpassword
}

# Nextcloud config info
nextcloud_config() {
	echo -e "\nNextcloud configuration"
	read -p "Please enter the nextcloud admin account: " nextclouduser
	read -p "Please enter the nextcloud admin password: " nextcloudpassword
	read -p "Please enter the nextcloud database password: " nextcloudmysqlpassword
	read -p "Please enter the nextcloud binding domain name: " nextclouddomainname
	read -p "Please enter the nextcloud version (example: 14.0.1): " nextcloudversion

	echo -e "\nNextcloud SSL configuration"
	echo -e "Please put certificate files and key files in the same directory as the script."
	read -p "Please enter the certificate file full name (example: nextcloud.crt): " nextcloudcertname
	read -p "Please enter the certificate key file full name(example: nextcloud.key): " nextcloudcertkeyname

	if [ -z ${mailselect} ]; then
		mailselect="1"
		echo -e "\nPlease select enable qq e-mail function."
		echo "1: Yes, the configuration function (Default)"
		echo "2: No, no configuration function"
		read -p "Enter your choice (1 , 2): " mailselect
	fi
	case "${mailselect}" in
	1)
		echo "yes configuration function"
		;;
	2)
		echo "no configuration function"
		;;
	*)
		echo "No input,Default values will be used"
		mailselect="1"
	esac

	if [ ${mailselect} = "1" ] ; then
		echo -e "\nOnly QQ mail is supported."
		echo -e "The password of the mailbox needs to be set up to generate the authorization code.\r"
		read -p "Please enter the mail address (example: 123@qq.com): " mailaddress
		read -p "Please enter the mail password (example: 23123545646): " mailpassword
	fi
}

# office soft select
officesoft_config() {
	if [ -z ${officeselect} ]; then
		officeselect="0"
		echo -e "\nPlease select office install mode."
		echo "1: Install linux for onlyoffice."
		echo "2: Install docker for onlyoffice."
		echo "3: Install linux for collaboraoffice."
		echo "4: Install docker for collaboraoffice."
		echo "0: Do not Install office software (default)"
		read -p "Enter your choice (1 , 2 , 3 , 4 or 0): " officeselect
	fi
	case "${officeselect}" in
	0)
		echo "do not Install office soft."
		;;
	1)
		echo "Install linux for onlyoffice."
		;;
	2)
		echo "Install docker for onlyoffice."
		;;
	3)
		echo "Install linux for collaboraoffice."
		;;
	4)
		echo "Install docker for collaboraoffice."
		;;
	*)
		echo "No input,Default values will be used"
		officeselect="0"
	esac

	# office binding domain name
	if [[ "${officeselect}" =~ ^[1234]$ ]] ; then
		read -p "Please enter the office binding domain name: " officedomainname
		echo -e "Please put certificate files and key files in the same directory as the script."
		read -p "Please enter the certificate file full name (example: office.crt): " officecertname
		read -p "Please enter the certificate key file full name(example: office.key): " officecertkeyname
	fi

	# onlyoffice secret and database password
	if [[ "${officeselect}" =~ ^[1]$ ]] ; then
		read -p "Please enter the onlyoffice secret password: " onlyofficesecret
		read -p "Please enter the onlyoffice database password: " onlyofficepassword
	fi

	if [[ "${officeselect}" =~ ^[2]$ ]] ; then
		read -p "Please enter the onlyoffice secret password: " onlyofficesecret
	fi

	# collaboraonline web user password
	if [[ "${officeselect}" =~ ^[34]$ ]] ; then
		read -p "Please enter the collaboraoffice admin account: " collaboraofficename
		read -p "Please enter the collaboraoffice admin password: " collaboraofficepassword
	fi
}

mysql_nextcloud() {
cat >/tmp/nextcloud.sql <<EOF
create database if not exists nextcloud;
create user nextcloud@localhost identified by '$nextcloudmysqlpassword';
grant all privileges on nextcloud.* to nextcloud@localhost;
flush privileges;
exit
EOF
mysql -u root -p$newmysqlpassword < /tmp/nextcloud.sql
rm -f /tmp/nextcloud.sql
}

nextcloud_redis() {
sed -i '$d' /opt/nextcloud/config/config.php
cat >>/opt/nextcloud/config/config.php <<"EOF"
  'filelocking.enabled' => true,
  'memcache.local' => '\OC\Memcache\APCu',
  'memcache.locking' => '\OC\Memcache\Redis',
  'memcache.distributed' => '\OC\Memcache\Redis',
  'redis' => array(
     'host' => 'localhost',
     'port' => 6379,
     ),
);
EOF
}

mysql_password() {
cat > modifymysqlpassword.exp <<EOF
#!/usr/bin/expect
set timeout 30
set password $mysqlpassword
set newpassword $newmysqlpassword
spawn mysql_secure_installation

expect "Enter password" {send "\$password\r";}
expect "New password" {send "\$newpassword\r";}
expect "Re-enter new password" {send "\$newpassword\r";}
expect "Do you wish to continue with the password provided" {send "y\r";}
expect "Change the password" {send "\r";}
expect "Remove anonymous users" {send "y\r";}
expect "Disallow root login remotely" {send "y\r";}
expect "Remove test database and access" {send "y\r";}
expect "Reload privilege tables now" {send "y\r";}
expect eof
EOF
}

onlyoffice_config() {
cat > onlyofficeconfig.exp <<EOF
#!/usr/bin/expect
set timeout 60
set password $onlyofficepassword
spawn bash documentserver-configure.sh

expect "Host" {send "localhost\r";}
expect "Database name" {send "onlyoffice\r";}
expect "User" {send "onlyoffice\r";}
expect "Password" {send "\$password\r";}
expect "Host" {send "localhost\r";}
expect "Host" {send "localhost\r";}
expect "User" {send "guest\r";}
expect "Password" {send "guest\r";}
expect eof
EOF
}


self_certificate() {
cat >/etc/nginx/cert/root.crt <<"EOF"
-----BEGIN CERTIFICATE-----
MIIDdzCCAl+gAwIBAgIJALIG4MqPPPyZMA0GCSqGSIb3DQEBCwUAMFIxCzAJBgNV
BAYTAkNOMQ4wDAYDVQQIDAVDaGluYTEVMBMGA1UEBwwMRGVmYXVsdCBDaXR5MRww
GgYDVQQKDBNEZWZhdWx0IENvbXBhbnkgTHRkMB4XDTE3MDkyMjA4MzcyMVoXDTE4
MDkyMjA4MzcyMVowUjELMAkGA1UEBhMCQ04xDjAMBgNVBAgMBUNoaW5hMRUwEwYD
VQQHDAxEZWZhdWx0IENpdHkxHDAaBgNVBAoME0RlZmF1bHQgQ29tcGFueSBMdGQw
ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDNdy+ik635t7yqsORWQxIO
n+CiTv/hSJGl+dgsbe3d/Wyki5WxC5MuGSUWT0WrKzw8MsqgTpOOYAMc0yhFiFs2
DL6QTs8Z7r5lUmcf4VhgZA/6X0dStWYmIMTQyKwOnefEDJWE0y4hAAlIRRTdbqzw
5rvp9Qot7us06Y3y/JqbfdNQ8ODaYTGQigrnxKeh0XUaulcfGVf1eXVmiFxtr4B7
O6d9XH3TvU1Ilu3FsBfa4dS2FG28LZDyHBy7a6ayG+QWNLidlDJyZgWm/mtHR1FC
ISny6hsGmFRQG767DWRLbJMt4ojuTbDaKEIhBU/w7fj5Kx5pSwbeYk/DGh30TpZT
AgMBAAGjUDBOMB0GA1UdDgQWBBTcu5hmHAnAhGeXX9aL+jMkak3DkDAfBgNVHSME
GDAWgBTcu5hmHAnAhGeXX9aL+jMkak3DkDAMBgNVHRMEBTADAQH/MA0GCSqGSIb3
DQEBCwUAA4IBAQA5f19FfnnNycL5PzUFeAtNT9Fo8UQbYqC8q2xvmQ0Lb0iDKj+T
esuiIO/lCArhKpco+4+dJPwZQeYUlT9qVcwcXnYfJwPwBTYXU2ngMMMmvONryeXb
k0255u14XQftX1koLiVHkV1Yc7NXGTWA5CMAqFMz1PkWN7Lv8jWFBz57WqNGoXqb
oKPXaPxgVxqSgryyMqfO+Ea8rfpZpZYVIONmcdednQrwEcJOi78V2zE79M0t65k8
+/ZjtMSSOKGAKlC+IOz29CLldX1G6wSzmV9RTBbzBCyVOG8t8IrdsaWjSGkh8JY3
K+SAnQK6U3rs8LRC2Z61PD65PfLKbPV4igab
-----END CERTIFICATE-----
EOF

cat >/etc/nginx/cert/root.key <<"EOF"
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDNdy+ik635t7yq
sORWQxIOn+CiTv/hSJGl+dgsbe3d/Wyki5WxC5MuGSUWT0WrKzw8MsqgTpOOYAMc
0yhFiFs2DL6QTs8Z7r5lUmcf4VhgZA/6X0dStWYmIMTQyKwOnefEDJWE0y4hAAlI
RRTdbqzw5rvp9Qot7us06Y3y/JqbfdNQ8ODaYTGQigrnxKeh0XUaulcfGVf1eXVm
iFxtr4B7O6d9XH3TvU1Ilu3FsBfa4dS2FG28LZDyHBy7a6ayG+QWNLidlDJyZgWm
/mtHR1FCISny6hsGmFRQG767DWRLbJMt4ojuTbDaKEIhBU/w7fj5Kx5pSwbeYk/D
Gh30TpZTAgMBAAECggEBAJPMY5i4UNKsR+wlOOuQbaHVgfpfh5Nf512Uftte7Ffe
n9Mxkal8oQ/tCI+m0H/Tpw3Kn5V3UI9/I14Nyw9RigM0YbRe7H1EDvPFtebp6+/S
que4uA6X7HYK5mkloRcWoYyWXMviOXGFnCe/gcXTglX8NDqUiREHp2w1gWXELdcg
/QcrmsUVjdR04j0wVW0hxwQ5Tah30L1VxBgylmdhqA94trdj3FdHCOp556IBj1gS
InXrcw3yPrwCkYQ9VW/BF3t9s3hfxzwmPpNy/HCR9mOCibzELFgPHnKBsoSYGBwf
DJF859S1wRN76RmBE/jdJJ14qIfcnDqTA8pjOl8WAFkCgYEA/5dnKi/eVf5UZ8II
6ZcNRW9OU+4ni9KhMXlMbPyttkJxJ99vWaR1gJTiGmVLa5UoV3GIRmImbIv+m70W
p+n2EaBHcTFaDE20dyeskofhRD7EfutPf54YYyG5Rk8Ip+TaoBPWMip/kk0GtwVt
85d0IgBsMjNbNkaCQoVJWQDkSJ8CgYEAzctFEzXv/DZoGkQJZGFL/zLpSM2jZ5fy
OEM8PHQ0gaPSvDfkv2Gr5oUs2cjl6Aun6f4fYTm7e9YClUVuezjHpheQVDi2zwwf
1h0WlMSvgEjhg2XXc+xfLEq5etCrxIocSEzO1XHWVMKzbMQ6U5R1hoYo6pyCOchH
ikbta7wmMc0CgYEA3QmtwXE2Yb4adsT6ejEU3Bifb7xFXQmiN6wEKTj4befV/jqg
DLFKoRGg3Fz/taGACud3iA731eXYIg2MG1kdYi7vufeJPZyx1l5sQyjZ6vAxdOXB
kcdCpfCTTzeob7JeVBPzqNzSCM8uYHeEmCZB2+nrqBp75lth6W9leGBqDFcCgYAc
YJQ00vI1uBbg0FLvOY9uMEoE1P5cUZJ/+Z17xJZc7gcoFxj+3uwCTIjjuxUgy0Kr
PHR9RqW4rMkMZleWvDyjhYpMYsmqgUR+lOJBP2Hn8aTPJqLwBD8Xb3JmIhIdduHx
gk3fFuR0KajuLZzRW55dH3DS8SPv7dMXmTIx8e7eXQKBgAUb26yJ+QT3FjOF7UVv
yluV7auwrVcGRhhF9XIpn9orYVRPcQY4gY2wqF1gYhHnz5VIWmXKxfDd7ZaPtx8L
UaF83K4cdQiD27YhnnVSBhygAbXhfui4acwQM5j6iuDyuSWWlaAiX+/Ac35gsLuk
r1DFDASTgBIecibWrId2vz5A
-----END PRIVATE KEY-----
EOF
}

nginx_repo() {
cat >/etc/yum.repos.d/nginx.repo <<"EOF"
# nginx.repo
# baseurl default connection address
# http://nginx.org/packages/centos/7/$basearch/

[nginx]
name=nginx repo
baseurl=https://mirrors.0diis.com/nginx/centos/7/$basearch/
gpgcheck=0
enabled=1
EOF
}

epel_repo() {
cat >/etc/yum.repos.d/epel.repo <<"EOF"
# epel.repo
# disable metalink enable baseurl
# baseurl default connection address
# http://download.fedoraproject.org/pub/epel/7/

[epel]
name=Extra Packages for Enterprise Linux 7 - $basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/epel/7/$basearch
#metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

[epel-debuginfo]
name=Extra Packages for Enterprise Linux 7 - $basearch - Debug
baseurl=https://mirrors.tuna.tsinghua.edu.cn/epel/7/$basearch/debug
#metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-7&arch=$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1

[epel-source]
name=Extra Packages for Enterprise Linux 7 - $basearch - Source
baseurl=https://mirrors.tuna.tsinghua.edu.cn/epel/7/SRPMS
#metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-source-7&arch=$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1
EOF
}

webtatic_repo() {
cat >/etc/yum.repos.d/webtatic.repo <<"EOF"
# webtatic.repo
# disable metalink enable baseurl
# baseurl default connection address
# https://repo.webtatic.com/yum/el7/

[webtatic]
name=Webtatic Repository EL7 - $basearch
baseurl=https://mirrors.0diis.com/webtatic/el7/$basearch/
#mirrorlist=https://mirror.webtatic.com/yum/el7/$basearch/mirrorlist
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-webtatic-el7

[webtatic-debuginfo]
name=Webtatic Repository EL7 - $basearch - Debug
baseurl=https://mirrors.0diis.com/webtatic/el7/$basearch/debug/
#mirrorlist=https://mirror.webtatic.com/yum/el7/$basearch/debug/mirrorlist
failovermethod=priority
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-webtatic-el7

[webtatic-source]
name=Webtatic Repository EL7 - $basearch - Source
baseurl=https://mirrors.0diis.com/webtatic/el7/SRPMS/
#mirrorlist=https://mirror.webtatic.com/yum/el7/SRPMS/mirrorlist
failovermethod=priority
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-webtatic-el7
EOF
}

mysql_repo() {
cat >/etc/yum.repos.d/mysql-community.repo <<"EOF"
# mysql-community.repo
# baseurl default connection address http://repo.mysql.com/yum/

[mysql-connectors-community]
name=MySQL Connectors Community
baseurl=https://mirrors.0diis.com/mysql/mysql-connectors-community/el/7/$basearch/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql

[mysql-tools-community]
name=MySQL Tools Community
baseurl=https://mirrors.0diis.com/mysql/mysql-tools-community/el/7/$basearch/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql

# Enable to use MySQL 5.5
[mysql55-community]
name=MySQL 5.5 Community Server
baseurl=https://mirrors.0diis.com/mysql/mysql-5.5-community/el/7/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql

# Enable to use MySQL 5.6
[mysql56-community]
name=MySQL 5.6 Community Server
baseurl=https://mirrors.0diis.com/mysql/mysql-5.6-community/el/7/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql

# Enable to use MySQL 5.7
[mysql57-community]
name=MySQL 5.7 Community Server
baseurl=https://mirrors.0diis.com/mysql/mysql-5.7-community/el/7/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql

# Enable to use MySQL 8.0
[mysql80-community]
name=MySQL 8.0 Community Server
baseurl=https://mirrors.0diis.com/mysql/mysql-8.0-community/el/7/$basearch/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql

[mysql-tools-preview]
name=MySQL Tools Preview
baseurl=https://mirrors.0diis.com/mysql/mysql-tools-preview/el/7/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql

[mysql-cluster-7.5-community]
name=MySQL Cluster 7.5 Community
baseurl=https://mirrors.0diis.com/mysql/mysql-cluster-7.5-community/el/7/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql

[mysql-cluster-7.6-community]
name=MySQL Cluster 7.6 Community
baseurl=https://mirrors.0diis.com/mysql/mysql-cluster-7.6-community/el/7/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql
EOF
}

nodejs_repo() {
cat >/etc/yum.repos.d/nodesource.repo <<"EOF"
# nodesource.repo
# baseurl default connection address
# https://rpm.nodesource.com/pub_8.x/el/7/$basearch

[nodesource]
name=Node.js Packages for Enterprise Linux 7 - $basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/nodesource/rpm_8.x/el/7/$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/NODESOURCE-GPG-SIGNING-KEY-EL

[nodesource-source]
name=Node.js for Enterprise Linux 7 - $basearch - Source
baseurl=https://mirrors.tuna.tsinghua.edu.cn/nodesource/rpm_8.x/el/7/SRPMS
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/NODESOURCE-GPG-SIGNING-KEY-EL
gpgcheck=1
EOF
}

onlyoffice_repo() {
cat >/etc/yum.repos.d/onlyoffice.repo <<"EOF"
# onlyoffice.repo
# baseurl default connection address
# http://download.onlyoffice.com/repo/centos/main/noarch/

[onlyoffice]
name=onlyoffice repo
baseurl=https://mirrors.0diis.com/onlyoffice/centos/main/noarch/
gpgcheck=1
enabled=1
EOF
}

collaboraoffice_repo() {
cat >/etc/yum.repos.d/collaboraoffice.repo <<"EOF"
# collaboraoffice.repo
# baseurl default connection address
# https://collaboraoffice.com/repos/CollaboraOnline/CODE-centos7

[collaboraoffice]
name=collaboraoffice repo
baseurl=https://mirrors.0diis.com/collaboraoffice/CollaboraOnline/CODE-centos7
enabled=1
EOF
}

nginx_onlyoffice() {
cat >/etc/nginx/conf.d/onlyoffice.conf <<"EOF"

include /etc/nginx/includes/onlyoffice-http.conf;

## Normal HTTP host
server {
    listen 80;
    listen [::]:80;
    server_name officedomainname;

    # Lets Encrypt SSL Certificate Directory
    location /.well-known/acme-challenge/ {
        root /opt/onlyoffice/; # Specify here where the challenge file is placed
    }

    # Tencent Cloud SSL Certificate Directory
    location /.well-known/pki-validation/ {
        root /opt/onlyoffice/; # Specify here where the challenge file is placed
    }

    # enforce https
    return 301 https://$server_name$request_uri;
}

## HTTP host for internal services
# server {
  # listen 127.0.0.1:80;
  # listen [::1]:80;
  # server_name localhost;
  # server_tokens off;
  
  # include /etc/nginx/includes/onlyoffice-documentserver-common.conf;
  # include /etc/nginx/includes/onlyoffice-documentserver-docservice.conf;
# }

## HTTPS host
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name officedomainname;
    # server_tokens off;
    root /usr/share/nginx/html;

    ## Strong SSL Security
    ## https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html
    ssl on;
    ssl_certificate /etc/nginx/cert/officecertname;
    ssl_certificate_key /etc/nginx/cert/officecertkeyname;
    ssl_verify_client off;

    ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";

    ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;
    ssl_session_cache  builtin:1000  shared:SSL:10m;

    ssl_prefer_server_ciphers   on;

    add_header Strict-Transport-Security max-age=31536000;
    # add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;

    ## [Optional] If your certficate has OCSP, enable OCSP stapling to reduce the overhead and latency of running SSL.
    ## Replace with your ssl_trusted_certificate. For more info see:
    ## - https://medium.com/devops-programming/4445f4862461
    ## - https://www.ruby-forum.com/topic/4419319
    ## - https://www.digitalocean.com/community/tutorials/how-to-configure-ocsp-stapling-on-apache-and-nginx
    # ssl_stapling on;
    # ssl_stapling_verify on;
    # ssl_trusted_certificate /etc/nginx/ssl/stapling.trusted.crt;
    # resolver 208.67.222.222 208.67.222.220 valid=300s; # Can change to your DNS resolver if desired
    # resolver_timeout 10s;

    ## [Optional] Generate a stronger DHE parameter:
    ##   cd /etc/ssl/certs
    ##   sudo openssl dhparam -out dhparam.pem 4096
    ##
    # ssl_dhparam /etc/ssl/certs/dhparam.pem;

    include /etc/nginx/includes/onlyoffice-documentserver-*.conf;

}
EOF
}

nginx_onlyoffice_docker() {
cat >/etc/nginx/conf.d/onlyoffice.conf <<"EOF"
server {
    listen 80;
    listen [::]:80;
    server_name officedomainname;

    # Lets Encrypt SSL Certificate Directory
    location /.well-known/acme-challenge/ {
        root /opt/onlyoffice/; # Specify here where the challenge file is placed
    }

    # Tencent Cloud SSL Certificate Directory
    location /.well-known/pki-validation/ {
        root /opt/onlyoffice/; # Specify here where the challenge file is placed
    }

    # enforce https
    return 301 https://$server_name$request_uri;
}

server {
    listen       443 ssl http2;
    listen       [::]:443 ssl http2;
    server_name  officedomainname;

    ssl_certificate /etc/nginx/cert/officecertname;
    ssl_certificate_key /etc/nginx/cert/officecertkeyname;

    ssl_prefer_server_ciphers on;

    location / {
        proxy_buffering off;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header REMOTE-HOST $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_pass https://localhost:8000;
    }
}
EOF
}

nginx_collaboraoffice() {
cat >/etc/nginx/conf.d/collaboraoffice.conf <<"EOF"
server {
    listen 80;
    listen [::]:80;
    server_name officedomainname;

    # Lets Encrypt SSL Certificate Directory
    location /.well-known/acme-challenge/ {
        root /opt/collaboraoffice/; # Specify here where the challenge file is placed
    }

    # Tencent Cloud SSL Certificate Directory
    location /.well-known/pki-validation/ {
        root /opt/collaboraoffice/; # Specify here where the challenge file is placed
    }
   
    # enforce https
    return 301 https://$server_name$request_uri;
}

server {
    listen       443 ssl http2;
    listen       [::]:443 ssl http2;
    server_name  officedomainname;

    ssl_certificate /etc/nginx/cert/officecertname;
    ssl_certificate_key /etc/nginx/cert/officecertkeyname;

    ssl_prefer_server_ciphers on;
    
    # static files
    location ^~ /loleaflet {
        proxy_pass https://localhost:9980;
        proxy_set_header Host $http_host;
    }

    # WOPI discovery URL
    location ^~ /hosting/discovery {
        proxy_pass https://localhost:9980;
        proxy_set_header Host $http_host;
    }

    # main websocket
    location ~ ^/lool/(.*)/ws$ {
        proxy_pass https://localhost:9980;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $http_host;
        proxy_read_timeout 36000s;
    }

    # download, presentation and image upload
    location ~ ^/lool {
        proxy_pass https://localhost:9980;
        proxy_set_header Host $http_host;
    }

    # Admin Console websocket
    location ^~ /lool/adminws {
        proxy_pass https://localhost:9980;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $http_host;
        proxy_read_timeout 36000s;
    }
}
EOF
}

nginx_nextcloud() {
cat >/etc/nginx/conf.d/nextcloud.conf <<"EOF"
upstream php-handler {
    server 127.0.0.1:9000;
    # Depending on your used PHP version
    #server unix:/var/run/php5-fpm.sock;
    #server unix:/var/run/php7-fpm.sock;
}

server {
    listen 80;
    listen [::]:80;
    server_name nextclouddomainname;

    # Lets Encrypt SSL Certificate Directory
    location /.well-known/acme-challenge/ {
        root /opt/nextcloud/; # Specify here where the challenge file is placed
    }

    # Tencent Cloud SSL Certificate Directory
    location /.well-known/pki-validation/ {
        root /opt/nextcloud/; # Specify here where the challenge file is placed
    }
   
    # enforce https
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name nextclouddomainname;

    # Use Mozilla's guidelines for SSL/TLS settings
    # https://mozilla.github.io/server-side-tls/ssl-config-generator/
    # NOTE: some settings below might be redundant
    ssl_certificate /etc/nginx/cert/nextcloudcertname;
    ssl_certificate_key /etc/nginx/cert/nextcloudcertkeyname;

    ssl_prefer_server_ciphers on;

    # Add headers to serve security related headers
    # Before enabling Strict-Transport-Security headers please read into this
    # topic first.
    add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;";
    #
    # WARNING: Only add the preload option once you read about
    # the consequences in https://hstspreload.org/. This option
    # will add the domain to a hardcoded list that is shipped
    # in all major browsers and getting removed from this list
    # could take several months.
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header X-Download-Options noopen;
    add_header X-Permitted-Cross-Domain-Policies none;
    add_header Referrer-Policy no-referrer;

    # Remove X-Powered-By, which is an information leak
    fastcgi_hide_header X-Powered-By;

    # Path to the root of your installation
    root /opt/nextcloud/;

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    # The following 2 rules are only needed for the user_webfinger app.
    # Uncomment it if you're planning to use this app.
    #rewrite ^/.well-known/host-meta /public.php?service=host-meta last;
    #rewrite ^/.well-known/host-meta.json /public.php?service=host-meta-json
    # last;

    location = /.well-known/carddav {
      return 301 $scheme://$host/remote.php/dav;
    }
    location = /.well-known/caldav {
      return 301 $scheme://$host/remote.php/dav;
    }

    # set max upload size
    client_max_body_size 20480M;

    # set Cache Configuration
    fastcgi_buffers 128 256k;
    fastcgi_buffer_size 1024k;
    client_body_buffer_size 1024k;

    # Enable gzip but do not remove ETag headers
    gzip on;
    gzip_vary on;
    gzip_comp_level 4;
    gzip_min_length 256;
    gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
    gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;

    # Uncomment if your server is build with the ngx_pagespeed module
    # This module is currently not supported.
    #pagespeed off;

    location / {
        rewrite ^ /index.php$request_uri;
    }

    location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)/ {
        deny all;
    }
    location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console) {
        deny all;
    }

    location ~ ^/(?:index|remote|public|cron|core/ajax/update|status|ocs/v[12]|updater/.+|ocs-provider/.+)\.php(?:$|/) {
        fastcgi_split_path_info ^(.+?\.php)(/.*)$;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param HTTPS on;
        #Avoid sending the security headers twice
        fastcgi_param modHeadersAvailable true;
        fastcgi_param front_controller_active true;
        fastcgi_pass php-handler;
        fastcgi_send_timeout 3600s;
        fastcgi_read_timeout 3600s;
        fastcgi_connect_timeout 3600s;
        fastcgi_intercept_errors on;
        fastcgi_request_buffering off;
    }

    location ~ ^/(?:updater|ocs-provider)(?:$|/) {
        try_files $uri/ =404;
        index index.php;
    }

    # Adding the cache control header for js and css files
    # Make sure it is BELOW the PHP block
    location ~ \.(?:css|js|woff|svg|gif)$ {
        try_files $uri /index.php$request_uri;
        add_header Cache-Control "public, max-age=15778463";
        # Add headers to serve security related headers (It is intended to
        # have those duplicated to the ones above)
        # Before enabling Strict-Transport-Security headers please read into
        # this topic first.
        # add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;";
        #
        # WARNING: Only add the preload option once you read about
        # the consequences in https://hstspreload.org/. This option
        # will add the domain to a hardcoded list that is shipped
        # in all major browsers and getting removed from this list
        # could take several months.
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header X-Robots-Tag none;
        add_header X-Download-Options noopen;
        add_header X-Permitted-Cross-Domain-Policies none;
        add_header Referrer-Policy no-referrer;

        # Optional: Don't log access to assets
        access_log off;
    }

    location ~ \.(?:png|html|ttf|ico|jpg|jpeg)$ {
        try_files $uri /index.php$request_uri;
        # Optional: Don't log access to other assets
        access_log off;
    }
}
EOF
}

install_docker() {
	# Check lvm2 , yum-utils , device-mapper-persistent-data package
	softwarepackage=("lvm2" "yum-utils" "device-mapper-persistent-data") 
	for softwarepackagevariable in ${softwarepackage[@]}
	do
		softwarepackagestate=$(rpm -qa | grep $softwarepackagevariable)
		if [ ! -n "$softwarepackagestate" ] ; then
			echo "Install $softwarepackagevariable software package"
			yum clean all
			rm -rf /var/lib/yum/history/*.sqlite
			yum install -y $softwarepackagevariable
		else
			echo "$softwarepackagevariable software packages have been installed."
		fi
	done

	# add docker aliyun repo
	yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

	# install docker-ce
	yum makecache fast
	yum -y install docker-ce

	# Start the docker service and configure the boot automatically.
	systemctl start docker
	systemctl enable docker

	# config Docker mirror accelerator and restat service
	sudo mkdir -p /etc/docker
	sudo tee /etc/docker/daemon.json <<-'EOF'
	{
	  "dns": ["114.114.114.114", "114.114.115.115"],
	  "registry-mirrors": ["https://z001byx4.mirror.aliyuncs.com"]
	}
	EOF
	systemctl daemon-reload
	systemctl restart docker
}

install_nginx() {
	# Install nginx repo
	echo "Install nginx repo"
	rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm

	# Modify nginx repo
	nginx_repo
	echo "Modify nginx repo"

	# Install nginx And openssl component package
	yum clean all
	rm -rf /var/cache/yum/
	rm -rf /var/lib/yum/history/*.sqlite
	yum install -y openssl nginx
	systemctl start nginx.service
	systemctl enable nginx.service

	# Optimizing nginx default configuration
	sed -i "/^$/{N;/\n$/D}" /etc/nginx/nginx.conf
	mv /etc/nginx/conf.d/default.conf /etc/nginx/default.conf
	sed -i "/tcp_nopush/a\ \n    server_tokens   off\;" /etc/nginx/nginx.conf
	sed -i "s/worker_processes  1/worker_processes  auto/g" /etc/nginx/nginx.conf
	sed -i "/worker_processes/a\worker_rlimit_nofile  65535\;" /etc/nginx/nginx.conf
	sed -i "s/worker_connections  1024/worker_connections  65535/g" /etc/nginx/nginx.conf
	sed -i "/include \/etc\/nginx\/conf.d\/\*.conf/i\    include \/etc\/nginx\/default.conf\;" /etc/nginx/nginx.conf
	sed -i "/listen       80\;/a\    listen       [::]:80\;" /etc/nginx/default.conf
	sed -i "/listen       [::]:80\;/a\    listen       443 ssl\;" /etc/nginx/default.conf
	sed -i "/listen       443 ssl\;/a\    listen       [::]:443 ssl\;" /etc/nginx/default.conf
	sed -i "/server_name/a\ \n    ssl_certificate \/etc\/nginx\/cert\/root.crt\;" /etc/nginx/default.conf
	sed -i "/ssl_certificate/a\    ssl_certificate_key \/etc\/nginx\/cert\/root.key\;" /etc/nginx/default.conf
	sed -i "/server_name/a\ \n    return       403\;" /etc/nginx/default.conf

	# Configure SSL support for nginx
	mkdir -p /etc/nginx/cert/
	self_certificate ; systemctl restart nginx
	
	# Configuration firewall to open service to nginx
	firewall-cmd --permanent --zone=public --add-service=http
	firewall-cmd --permanent --zone=public --add-service=https
	firewall-cmd --reload
}

install_php() {
	# Install epel repo
	echo "Install epel repo"
	rpm -Uvh http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

	# Modify epel repo
	epel_repo
	echo "Modify epel repo"

	# Install webtatic repo
	echo "Install webtatic repo"
	rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

	# Modify webtatic repo
	webtatic_repo
	echo "Modify webtatic repo"

	# Install php and other component package
	yum clean all
	rm -rf /var/cache/yum/
	rm -rf /var/lib/yum/history/*.sqlite
	yum install -y php72w php72w-cli php72w-fpm php72w-common
	yum install -y redis php72w-opcache php72w-pecl-apcu php72w-pecl-redis
	yum install -y php72w-process php72w-intl php72w-gd php72w-mbstring php72w-mysql php72w-pgsql php72w-pdo php72w-xml php72w-pecl-imagick

	# Configuring PHP-FPM service
	sed -i "s/user \= apache/user \= nginx/g" /etc/php-fpm.d/www.conf
	sed -i "s/group \= apache/group \= nginx/g" /etc/php-fpm.d/www.conf
	sed -i "s/\;env\[TMP\]/env\[TMP\]/g" /etc/php-fpm.d/www.conf
	sed -i "s/\;env\[TEMP\]/env\[TEMP\]/g" /etc/php-fpm.d/www.conf
	sed -i "s/\;env\[PATH\]/env\[PATH\]/g" /etc/php-fpm.d/www.conf
	sed -i "s/\;env\[TMPDIR\]/env\[TMPDIR\]/g" /etc/php-fpm.d/www.conf
	sed -i "s/\;env\[HOSTNAME\]/env\[HOSTNAME\]/g" /etc/php-fpm.d/www.conf
	mkdir -p /var/lib/php/session
	chown nginx:nginx -R /var/lib/php/session/

	# Configuring Php opcache component
	sed -i "s/\;opcache.enable_cli\=0/opcache.enable_cli\=1/g" /etc/php.d/opcache.ini
	sed -i "s/\;opcache.save_comments\=1/opcache.save_comments\=1/g" /etc/php.d/opcache.ini
	sed -i "s/\;opcache.revalidate_freq\=2/opcache.revalidate_freq\=1/g" /etc/php.d/opcache.ini
	sed -i "s/opcache.max_accelerated_files\=4000/opcache.max_accelerated_files\=10000/g" /etc/php.d/opcache.ini

	# gcc and ufraw pango pango-devel
	softwarepackage=("gcc" "pango" "pango-devel" "ufraw") 
	for softwarepackagevariable in ${softwarepackage[@]}
	do
		softwarepackagestate=$(rpm -qa | grep $softwarepackagevariable)
		if [ ! -n "$softwarepackagestate" ] ; then
			echo "Install $softwarepackagevariable software package"
			yum clean all
			rm -rf /var/lib/yum/history/*.sqlite
			yum install -y $softwarepackagevariable
		else
			echo "$softwarepackagevariable software packages have been installed."
		fi
	done

	# Install Smbclient-Php
	yum clean all
	rm -rf /var/cache/yum/
	rm -rf /var/lib/yum/history/*.sqlite
	yum -y install php72w-devel
	yum -y install libsmbclient libsmbclient-devel
	pecl install smbclient

	# add smbclient.so to /etc/php.d/
  sudo tee /etc/php.d/smbclient.ini <<-'EOF'
	; Enable Samba client extension module
	extension = smbclient.so
	EOF
	
	# Start the redis and php-fpm service and configure the boot automatically.
	systemctl start redis php-fpm
	systemctl enable redis php-fpm
}

install_mysql() {
	# Check And Uninstall mariadb package
	mariadbsoftwarepackagestate=$(rpm -qa | grep mariadb)
	if [ "$softwarepackagestate" != "" ] ; then
		rpm -e --nodeps mariadb-libs-*
		echo "Uninstall mariadb software package"
	fi

	# Check perl , expect , net-tools , yum-utils package
	softwarepackage=("perl" "expect" "net-tools" "yum-utils") 
	for softwarepackagevariable in ${softwarepackage[@]}
	do
		softwarepackagestate=$(rpm -qa | grep $softwarepackagevariable)
		if [ ! -n "$softwarepackagestate" ] ; then
			echo "Install $softwarepackagevariable software package"
			yum clean all
			rm -rf /var/lib/yum/history/*.sqlite
			yum install -y $softwarepackagevariable
		else
			echo "$softwarepackagevariable software packages have been installed."
		fi
	done

	# Install mysql Repo
	echo "Install mysql Repo"
	rpm -Uvh https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm

	# Modify mysql repo
	mysql_repo
	echo "Modify mysql repo"

	# Modify mysql repo default mysql 5.7 version
	if [ ${dbselect} = "1" ] ; then
		sudo yum-config-manager --disable mysql80-community
		sudo yum-config-manager --enable mysql57-community
	fi

	# Install mysql service
	yum clean all
	rm -rf /var/cache/yum/
	rm -rf /var/lib/yum/history/*.sqlite
	yum -y install mysql-community-server mysql-community-libs-compat

	# start mysqld service
	systemctl start mysqld

	# Add different parameters according to database version
	mysqlversion=$(rpm -qa | grep mysql | grep server | awk -F 'server-' '{print $2}' | awk -F '.' '{print $1}')
	if [ "${mysqlversion}" -lt 8 ] ; then
		echo -e "\nvalidate_password = off\n" >> /etc/my.cnf
	else
		echo -e "\n# validate_password = off" >> /etc/my.cnf
		echo -e "validate_password.policy = 0" >> /etc/my.cnf
		echo -e "validate_password.length = 0" >> /etc/my.cnf
		echo -e "validate_password.number_count = 0" >> /etc/my.cnf
		echo -e "validate_password.mixed_case_count = 0" >> /etc/my.cnf
		echo -e "validate_password.special_char_count = 0\n" >> /etc/my.cnf
		echo -e "default-authentication-plugin=mysql_native_password\n" >> /etc/my.cnf
	fi
	systemctl restart mysqld

	# completes restart service
	mysqlpassword=$(sudo grep 'temporary password' /var/log/mysqld.log | awk -F 'localhost: ' '{print $2}')
	mysql_password ; chmod +x modifymysqlpassword.exp ; expect modifymysqlpassword.exp ; rm -f modifymysqlpassword.exp
	systemctl restart mysqld
}

install_nextcloud() {
	# Check wget and unzip package
	softwarepackage=("wget" "unzip") 
	for softwarepackagevariable in ${softwarepackage[@]}
	do
		softwarepackagestate=$(rpm -qa | grep $softwarepackagevariable)
		if [ ! -n "$softwarepackagestate" ] ; then
			echo "Install $softwarepackagevariable software package"
			yum clean all
			rm -rf /var/lib/yum/history/*.sqlite
			yum install -y $softwarepackagevariable
		else
			echo "$softwarepackagevariable software packages have been installed."
		fi
	done

	# Down nextcloud
	wget  https://mirrors.0diis.com/nextcloud/server/releases/nextcloud-$nextcloudversion.zip

	# Decompress and move to the opt directory and assign authority.
	unzip nextcloud-*.zip
	mv nextcloud/ /opt/
	rm -f nextcloud-*.zip
	chown nginx:nginx -R /opt/nextcloud/

	# Configure nginx to nextcloud virtual host
	nginx_nextcloud
	sed -i "s/nextclouddomainname/$nextclouddomainname/g" /etc/nginx/conf.d/nextcloud.conf

	# Configure nginx to nextcloud virtual host cert info
	mv -f $scriptpath/$nextcloudcertname $scriptpath/$nextcloudcertkeyname -t /etc/nginx/cert/
	sed -i "s/nextcloudcertname/$nextcloudcertname/g" /etc/nginx/conf.d/nextcloud.conf
	sed -i "s/nextcloudcertkeyname/$nextcloudcertkeyname/g" /etc/nginx/conf.d/nextcloud.conf

	# Configure nextcloud database
	mysql_nextcloud

	# Install Nextcloud through command line
	sudo -u nginx php /opt/nextcloud/occ maintenance:install \
	--admin-user "$nextclouduser" \
	--admin-pass "$nextcloudpassword" \
	--database "mysql" \
	--database-name "nextcloud" \
	--database-user "nextcloud" \
	--database-pass "$nextcloudmysqlpassword"

	sudo -u nginx php /opt/nextcloud/occ background:cron
	sudo -u nginx php /opt/nextcloud/occ config:system:set trusted_domains 0 --value=$nextclouddomainname
	sudo -u nginx php /opt/nextcloud/occ config:system:set overwrite.cli.url --value=https://$nextclouddomainname

	# Configure Nextcloud Email Info
	if [ ${mailselect} = "1" ] ; then
		maildomain=$(echo $mailaddress | awk -F '@' '{print $2}')
		mailfromaddress=$(echo $mailaddress | awk -F '@' '{print $1}')
		sudo -u nginx php /opt/nextcloud/occ config:system:set mail_smtpmode --value=smtp
		sudo -u nginx php /opt/nextcloud/occ config:system:set mail_smtpauthtype --value=LOGIN
		sudo -u nginx php /opt/nextcloud/occ config:system:set mail_smtpsecure --value=ssl
		sudo -u nginx php /opt/nextcloud/occ config:system:set mail_from_address --value=$mailfromaddress
		sudo -u nginx php /opt/nextcloud/occ config:system:set mail_domain --value=$maildomain
		sudo -u nginx php /opt/nextcloud/occ config:system:set mail_smtpauth --value=1
		sudo -u nginx php /opt/nextcloud/occ config:system:set mail_smtphost --value=smtp.qq.com
		sudo -u nginx php /opt/nextcloud/occ config:system:set mail_smtpport --value=465
		sudo -u nginx php /opt/nextcloud/occ config:system:set mail_smtpname --value=$mailaddress
		sudo -u nginx php /opt/nextcloud/occ config:system:set mail_smtppassword --value=$mailpassword
	fi

	# Configure Nextcloud external storage
	sudo -u nginx php /opt/nextcloud/occ app:enable files_external
	sudo -u nginx php /opt/nextcloud/occ config:app:set files_external allow_user_mounting --value="yes"
	sudo -u nginx php /opt/nextcloud/occ config:app:set files_external user_mounting_backends --value="ftp,dav,owncloud,sftp,amazons3,swift,smb,\\OC\\Files\\Storage\\SFTP_Key,\\OC\\Files\\Storage\\SMB_OC"

	# Configure Nextcloud 15.x data optimization
	sudo -u nginx php /opt/nextcloud/occ db:convert-filecache-bigint --quiet

	# Increase planning tasks for nextcloud
	echo -e "*/15  *  *  *  * php -f /opt/nextcloud/cron.php" >> /var/spool/cron/nginx

	# Configure Nextcloud for redis
	nextcloud_redis

	# Configuration completes restart service
	systemctl restart nginx php-fpm redis
}

nextcloud_collaboraoffice() {
	# Get the latest version of collaboraoffice on GitHub
	officelatestversion=$(curl https://mirrors.0diis.com/github/nextcloud/richdocuments/releases/latest | awk -F 'tag/' '{print $2}' | awk -F '">' '{print $1}')

	# Down collaboraoffice for nextcloud pack
	wget  https://mirrors.0diis.com/github/nextcloud/richdocuments/releases/download/$officelatestversion/richdocuments.tar.gz

	# Decompress files to nextcloud apps directory and delete file
	tar -xzvf richdocuments.tar.gz -C /opt/nextcloud/apps
	rm -f richdocuments*.tar.gz
	chown nginx:nginx -R /opt/nextcloud/apps/richdocuments*

	# Start the collaboraoffice and configure the link address.
	sudo -u nginx php /opt/nextcloud/occ app:enable richdocuments
	sudo -u nginx php /opt/nextcloud/occ config:app:set richdocuments wopi_url --value="https://$officedomainname"
}

install_collaboraoffice() {
	# Import collaboraoffice Key
	wget  https://collaboraoffice.com/repos/CollaboraOnline/CODE-centos7/repodata/repomd.xml.key && rpm --import repomd.xml.key && rm -f repomd.xml.key

	# Install Collaboraoffice Repo
	echo "Install Collaboraoffice Repo"
	collaboraoffice_repo

	# Install loolwsd and CODE-brand component package
	yum clean all
	rm -rf /var/cache/yum/
	rm -rf /var/lib/yum/history/*.sqlite
	yum install --nogpgcheck -y loolwsd CODE-brand

	# Configure Collaboraoffice SSL Path Info And Console User Password
	collaboraofficedomain=$(echo ${nextclouddomainname//./\\\\.})
	sed -i "s/<\/username>/$collaboraofficename<\/username>/g" /etc/loolwsd/loolwsd.xml
	sed -i "s/<\/password>/$collaboraofficepassword<\/password>/g" /etc/loolwsd/loolwsd.xml
	sed -i "s/\/etc\/loolwsd\/ca-chain.cert.pem<\/ca_file_path>/<\/ca_file_path>/g" /etc/loolwsd/loolwsd.xml
	sed -i "s/\/etc\/loolwsd\/cert.pem<\/cert_file_path>/\/etc\/loolwsd\/$officecertname<\/cert_file_path>/g" /etc/loolwsd/loolwsd.xml
	sed -i "s/\/etc\/loolwsd\/key.pem<\/key_file_path>/\/etc\/loolwsd\/$officecertkeyname<\/key_file_path>/g" /etc/loolwsd/loolwsd.xml
	sed -i "/<host desc\=\"Regex pattern of hostname to allow or deny.\" allow\=\"true\">localhost<\/host>/a\            <host desc\=\"Regex pattern of hostname to allow or deny.\" allow\=\"true\">$collaboraofficedomain<\/host>" /etc/loolwsd/loolwsd.xml

	# Configure nginx to collaboraoffice virtual host
	nginx_collaboraoffice
	sed -i "s/officedomainname/$officedomainname/g" /etc/nginx/conf.d/collaboraoffice.conf

	# Mobile certificates to nginx certificate directory
	cp $scriptpath/$officecertname $scriptpath/$officecertkeyname -t /etc/loolwsd/
	mv -f $scriptpath/$officecertname $scriptpath/$officecertkeyname -t /etc/nginx/cert/
	sed -i "s/officecertname/$officecertname/g" /etc/nginx/conf.d/collaboraoffice.conf
	sed -i "s/officecertkeyname/$officecertkeyname/g" /etc/nginx/conf.d/collaboraoffice.conf
	systemctl restart nginx

	# Start the loolwsd service and configure the boot automatically.
	systemctl start loolwsd
	systemctl enable loolwsd

	# Install nextcloud for collaboraoffice software package
	nextcloud_collaboraoffice
}

install_collaboraoffice_docker() {
	# Configure nginx to collaboraoffice virtual host
	nginx_collaboraoffice
	sed -i "s/officedomainname/$officedomainname/g" /etc/nginx/conf.d/collaboraoffice.conf

	# Mobile certificates to nginx certificate directory
	mv -f $scriptpath/$officecertname $scriptpath/$officecertkeyname -t /etc/nginx/cert/
	sed -i "s/officecertname/$officecertname/g" /etc/nginx/conf.d/collaboraoffice.conf
	sed -i "s/officecertkeyname/$officecertkeyname/g" /etc/nginx/conf.d/collaboraoffice.conf
	systemctl restart nginx

	# pull collabora mirror
	collaboraofficedomain=$(echo ${nextclouddomainname//./\\\\.})
	docker pull collabora/code
	docker run -t -d -p 127.0.0.1:9980:9980 -e "domain=$collaboraofficedomain" \
	  -e "username=$collaboraofficename" \
	  -e "password=$collaboraofficepassword" \
	  --restart always --cap-add MKNOD collabora/code

	# Restart docker service after 120 seconds delay
	sleep 120s
	systemctl restart docker

	# Install nextcloud for collaboraoffice software package
	nextcloud_collaboraoffice
}

nextcloud_onlyoffice() {
	# Get the latest version of onlyoffice on GitHub
	officelatestversion=$(curl https://mirrors.0diis.com/github/ONLYOFFICE/onlyoffice-nextcloud/releases/latest | awk -F 'tag/v' '{print $2}' | awk -F '">' '{print $1}')

	# Down onlyoffice for nextcloud pack
	wget  https://mirrors.0diis.com/github/ONLYOFFICE/onlyoffice-nextcloud/releases/download/v$officelatestversion/onlyoffice.tar.gz

	# Decompress files to nextcloud apps directory and delete file
	tar -xzvf onlyoffice.tar.gz -C /opt/nextcloud/apps
	rm -f onlyoffice*.tar.gz
	chown nginx:nginx -R /opt/nextcloud/apps/onlyoffice*

	# Start the onlyoffice and configure the link address.
	sudo -u nginx php /opt/nextcloud/occ app:enable onlyoffice
	sudo -u nginx php /opt/nextcloud/occ config:app:set onlyoffice jwt_secret --value="$onlyofficesecret"
	sudo -u nginx php /opt/nextcloud/occ config:app:set onlyoffice DocumentServerUrl --value="https://$officedomainname"
}

install_onlyoffice() {
	# Install onlyoffice and node.js repo
	echo "Install onlyoffice and node.js repo"
	curl -sL https://rpm.nodesource.com/setup_8.x | bash -
	rpm -Uvh http://download.onlyoffice.com/repo/centos/main/noarch/onlyoffice-repo.noarch.rpm

	# Modify onlyoffice and node.js repo
	echo "Modify onlyoffice and node.js repo"
	nodejs_repo
	onlyoffice_repo

	# Install nodejs , postgresql , rabbitmq , onlyoffice package
	yum clean all
	rm -rf /var/cache/yum/
	rm -rf /var/lib/yum/history/*.sqlite
	yum install -y nodejs postgresql postgresql-server rabbitmq-server onlyoffice-documentserver

	# Initialization postgresql database
	sudo service postgresql initdb
	sudo chkconfig postgresql on
	sed -i "s/host    all             all             127.0.0.1\/32            ident/host    all             all             127.0.0.1\/32            trust/g" /var/lib/pgsql/data/pg_hba.conf
	sed -i "s/host    all             all             ::1\/128                 ident/host    all             all             ::1\/128                 trust/g" /var/lib/pgsql/data/pg_hba.conf
	sudo service postgresql restart

	# Import onlyoffice database
	cd /tmp
	sudo -u postgres psql -c "CREATE DATABASE onlyoffice;"
	sudo -u postgres psql -c "CREATE USER onlyoffice WITH password '$onlyofficepassword';"
	sudo -u postgres psql -c "GRANT ALL privileges ON DATABASE onlyoffice TO onlyoffice;"
	cd $scriptpath

	# Start the rabbitmq and supervisord service and configure the boot automatically.
	sudo service rabbitmq-server start
	sudo systemctl enable rabbitmq-server
	sudo service supervisord start
	sudo systemctl enable supervisord

	# Configure onlyoffice info
	mkdir -p /etc/onlyoffice/documentserver-example/
	onlyoffice_config ; chmod +x onlyofficeconfig.exp ; expect onlyofficeconfig.exp ; rm -f onlyofficeconfig.exp

	# config nginx for onlyoffice
	nginx_onlyoffice
	rm -f /etc/nginx/conf.d/onlyoffice-documentserver.conf
	sed -i "s/officedomainname/$officedomainname/g" /etc/nginx/conf.d/onlyoffice.conf

	# Mobile certificates to nginx certificate directory
	mv -f $scriptpath/$officecertname $scriptpath/$officecertkeyname -t /etc/nginx/cert/
	sed -i "s/officecertname/$officecertname/g" /etc/nginx/conf.d/onlyoffice.conf
	sed -i "s/officecertkeyname/$officecertkeyname/g" /etc/nginx/conf.d/onlyoffice.conf
	systemctl restart nginx

	# Configure onlyoffce secret options and restart service
	sed -i "s/\"inbox\"\: false/\"inbox\"\: true/g" /etc/onlyoffice/documentserver/local.json
	sed -i "s/\"outbox\"\: false/\"outbox\"\: true/g" /etc/onlyoffice/documentserver/local.json
	sed -i "s/\"browser\"\: false/\"browser\"\: true/g" /etc/onlyoffice/documentserver/local.json
	sed -i "s/\"string\"\: \"secret\"/\"string\"\: \"$onlyofficesecret\"/g" /etc/onlyoffice/documentserver/local.json
	supervisorctl restart all

	# Install nextcloud for collaboraoffice software package
	nextcloud_onlyoffice
}

install_onlyoffice_docker() {
	# Configure nginx to collaboraoffice virtual host
	nginx_onlyoffice_docker
	sed -i "s/officedomainname/$officedomainname/g" /etc/nginx/conf.d/onlyoffice.conf

	# Mobile certificates to nginx certificate directory
	mkdir -p /etc/onlyoffice/
	cp $scriptpath/$officecertname $scriptpath/$officecertkeyname -t /etc/onlyoffice
	mv -f $scriptpath/$officecertname $scriptpath/$officecertkeyname -t /etc/nginx/cert/
	sed -i "s/officecertname/$officecertname/g" /etc/nginx/conf.d/onlyoffice.conf
	sed -i "s/officecertkeyname/$officecertkeyname/g" /etc/nginx/conf.d/onlyoffice.conf
	systemctl restart nginx

	# pull nginx_onlyoffice mirror and docker pull onlyoffice/documentserver
	docker pull onlyoffice/documentserver
	echo -e "JWT_ENABLED=true" > /etc/onlyoffice/onlyoffice.conf
	echo -e "JWT_SECRET=$onlyofficesecret" >> /etc/onlyoffice/onlyoffice.conf
	echo -e "SSL_KEY_PATH=/var/www/onlyoffice/Data/certs/$officecertkeyname" >> /etc/onlyoffice/onlyoffice.conf
	echo -e "SSL_CERTIFICATE_PATH=/var/www/onlyoffice/Data/certs/$officecertname" >> /etc/onlyoffice/onlyoffice.conf
	sudo docker run -i -t -d -p 127.0.0.1:8000:443 --env-file=/etc/onlyoffice/onlyoffice.conf -v /etc/onlyoffice/:/var/www/onlyoffice/Data/certs --restart always onlyoffice/documentserver

	# Install nextcloud for collaboraoffice software package
	nextcloud_onlyoffice
}

# info guide
mysql_config
nextcloud_config
officesoft_config
echo -e "\r\r\r\r"
echo -e "Please check if configuration information is normal."
if [ -z ${installselect} ]; then
	echo "Please select install or exit."
	echo "1: Install"
	echo "2: Exit Script"
	read -p "Enter your choice (1 , 2): " installselect
fi

if [ ${installselect} = "2" ] ; then
	exit
elif [ ${installselect} = "1" ] ; then
	echo -e "\nStart installation, please wait..."
	init_system
	install_nginx 2>&1>/dev/null
	install_php 2>&1>/dev/null
	install_mysql 2>&1>/dev/null
	install_nextcloud 2>&1>/dev/null

	# office install guide
	if [ ${officeselect} = "1" ] ; then
		install_onlyoffice 2>&1>/dev/null
	elif [ ${officeselect} = "2" ] ; then
		install_docker 2>&1>/dev/null
		install_onlyoffice_docker 2>&1>/dev/null
	elif [ ${officeselect} = "3" ] ; then
		install_collaboraoffice 2>&1>/dev/null
	elif [ ${officeselect} = "4" ] ; then
		install_docker 2>&1>/dev/null
		install_collaboraoffice_docker 2>&1>/dev/null
	fi

	# Display nextcloud configuration information.
	echo -e "\ninstallation is complete"
	echo -e "\nNextcloud Info"
	echo -e "Web Url: https://$nextclouddomainname"
	echo -e "administrator account: $nextclouduser"
	echo -e "administrator password: $nextcloudpassword"
	echo -e "Database Info: user: nextcloud Password: $nextcloudmysqlpassword"

	# Display office configuration information.
	if [[ "${officeselect}" =~ ^[1234]$ ]] ; then
		echo -e "\nOffice Software Info"
		echo -e "Web Url: https://$officedomainname"
	fi

	if [ ${officeselect} = "1" ] ; then
		echo -e "Secret Password: $onlyofficesecret"
		echo -e "Database Info: user: onlyoffice Password: $onlyofficepassword"
	elif [ ${officeselect} = "2" ] ; then
		echo -e "Secret Password: $onlyofficesecret"
	elif [[ "${officeselect}" =~ ^[34]$ ]] ; then
		echo -e "Web Console Url: https://$officedomainname/loleaflet/dist/admin/admin.html"
		echo -e "administrator account: $collaboraofficename"
		echo -e "administrator password: $collaboraofficepassword"
	fi
fi
