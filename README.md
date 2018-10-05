使用说明

本脚本基于 Centos 7 + nginx + mysql + nextcloud + php-fpm + redis + onlyoffice for collaboraoffice 实现一键安装脚本

所有全通过 mirrors.0diis.com 反向代理到各软件官方仓库源

其中 office 软件包 支持 yum 安装 以及 docker 安装 可凭喜好选择

docker 使用阿里云加速器 pull 镜像速度很快无需担心 选择 docker 的运行方式 pull 过慢的问题

nextcloud 常规自检有关于邮箱的配置，在一件脚本里面也实现了改功能 （目前仅支持使用QQ 邮箱）

备注：脚本运行时候强制要求使用 SSL 证书 ， 需要提前把证书放在和脚本运行的同目录下以便脚本可以自动复制脚本到对应位置

