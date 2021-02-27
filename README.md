# LXD/LXC config

## ホスト
`Ubuntu 20.04 LTS` か `Ubuntu 18.04 LTS` の想定。
```bash
$ lsb_release -idc
Distributor ID: Ubuntu
Description:    Ubuntu 20.04.2 LTS
Codename:       focal
```
```bash
Distributor ID: Ubuntu
Description:    Ubuntu 18.04.5 LTS
Codename:       bionic
```

## ストレージプールの準備(Optional)

```bash
$ sudo lvcreate --size 100G --name lv_lxd01 vg_vm01
```
```bash
$ sudo lvdisplay -C
  LV                 VG       Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  (..snip..)
  lv_lxd01           vg_vm01  -wi-a----- 100.00g
  (..snip..)
```

## LXD のインストール
### Ubuntu 20.04 LTS
```bash
$ sudo snap install lxd --channel=4.0/stable
$ lxd --version
4.0.4
```
### Ubuntu 18.04 LTS
```bash
$ sudo snap install lxd --channel=3.0/stable
$ lxd --version
3.0.3
```

## 初期設定
```bash
$ sudo lxd init
Would you like to use LXD clustering? (yes/no) [default=no]: no
Do you want to configure a new storage pool? (yes/no) [default=yes]: yes
Name of the new storage pool [default=default]: default
Name of the storage backend to use (lvm, zfs, ceph, btrfs, dir) [default=zfs]: btrfs
Create a new BTRFS pool? (yes/no) [default=yes]: yes
Would you like to use an existing empty block device (e.g. a disk or partition)? (yes/no) [default=no]: yes
Path to the existing block device: /dev/vg_vm01/lv_lxd01
Would you like to connect to a MAAS server? (yes/no) [default=no]: no
Would you like to create a new local network bridge? (yes/no) [default=yes]: yes
What should the new bridge be called? [default=lxdbr0]: lxdbr0
What IPv4 address should be used? (CIDR subnet notation, “auto” or “none”) [default=auto]: auto
What IPv6 address should be used? (CIDR subnet notation, “auto” or “none”) [default=auto]: auto
Would you like LXD to be available over the network? (yes/no) [default=no]: no
Would you like stale cached images to be updated automatically? (yes/no) [default=yes] yes
Would you like a YAML "lxd init" preseed to be printed? (yes/no) [default=no]: yes
config: {}
networks:
- config:
    ipv4.address: auto
    ipv6.address: auto
  description: ""
  name: lxdbr0
  type: ""
storage_pools:
- config:
    source: /dev/vg_vm01/lv_lxd01
  description: ""
  name: default
  driver: btrfs
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      network: lxdbr0
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default
cluster: null
```

## 確認
```bash
$ lxc network list
+-----------------+----------+---------+-------------+---------+
|      NAME       |   TYPE   | MANAGED | DESCRIPTION | USED BY |
+-----------------+----------+---------+-------------+---------+
(..snip..)
+-----------------+----------+---------+-------------+---------+
| docker0         | bridge   | NO      |             | 0       |
+-----------------+----------+---------+-------------+---------+
| enp2s0          | physical | NO      |             | 0       |
+-----------------+----------+---------+-------------+---------+
| lxdbr0          | bridge   | YES     |             | 1       |
+-----------------+----------+---------+-------------+---------+
| virbr0          | bridge   | NO      |             | 0       |
+-----------------+----------+---------+-------------+---------+
(..snip..)
```
- Ubuntu 20.04 LTS
  ```bash
  $ lxc network info lxdbr0
  Name: lxdbr0
  MAC address: 00:16:3e:3b:b6:01
  MTU: 1500
  State: up
  
  Ips:
    inet  10.129.195.1
    inet6 fd42:b783:772f:df72::1
  
  Network usage:
    Bytes received: 0B
    Bytes sent: 0B
    Packets received: 0
    Packets sent: 0
  ```
- Ubuntu 18.04 LTS
  ```bash
  $ lxc network show lxdbr0
  ```

```bash
$ ip addr show lxdbr0
19: lxdbr0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default qlen 1000
    link/ether 00:16:3e:3b:b6:01 brd ff:ff:ff:ff:ff:ff
    inet 10.129.195.1/24 scope global lxdbr0
       valid_lft forever preferred_lft forever
    inet6 fd42:b783:772f:df72::1/64 scope global
       valid_lft forever preferred_lft forever
```

## インスタンスの作成
```bash
$ lxc launch ubuntu:20.04 lxd-ubu2004x01
Creating lxd-ubu2004x01
```

### 確認
```bash
$ lxc image list local:
+-------+--------------+--------+---------------------------------------------+--------------+-----------+----------+-----------------------------+
| ALIAS | FINGERPRINT  | PUBLIC |                 DESCRIPTION                 | ARCHITECTURE |   TYPE    |   SIZE   |         UPLOAD DATE         |
+-------+--------------+--------+---------------------------------------------+--------------+-----------+----------+-----------------------------+
|       | e0c3495ffd48 | no     | ubuntu 20.04 LTS amd64 (release) (20201210) | x86_64       | CONTAINER | 356.23MB | Jan 1, 2021 at 9:47am (UTC) |
+-------+--------------+--------+---------------------------------------------+--------------+-----------+----------+-----------------------------+
```
```bash
$ lxc list
+----------------+---------+----------------------+-----------------------------------------------+-----------+-----------+
|      NAME      |  STATE  |         IPV4         |                     IPV6                      |   TYPE    | SNAPSHOTS |
+----------------+---------+----------------------+-----------------------------------------------+-----------+-----------+
| lxd-ubu2004x01 | RUNNING | 10.129.195.85 (eth0) | fd42:b783:772f:df72:216:3eff:fe90:c997 (eth0) | CONTAINER | 0         |
+----------------+---------+----------------------+-----------------------------------------------+-----------+-----------+
```
```bash
$ lxc storage list
+---------+-------------+--------+-----------------------+---------+
|  NAME   | DESCRIPTION | DRIVER |        SOURCE         | USED BY |
+---------+-------------+--------+-----------------------+---------+
| default |             | btrfs  | /dev/vg_vm01/lv_lxd01 | 3       |
+---------+-------------+--------+-----------------------+---------+
```
```bash
$ lxc storage info default
info:
  description: ""
  driver: btrfs
  name: default
  space used: 1.08GB
  total space: 107.37GB
used by:
  images:
  - e0c3495ffd489748aa5151628fa56619e6143958f041223cb4970731ef939cb6
  instances:
  - lxd-ubu2004x01
  profiles:
  - default
```
```bash
$ lxc profile show default
config: {}
description: Default LXD profile
devices:
  eth0:
    name: eth0
    network: lxdbr0
    type: nic
  root:
    path: /
    pool: default
    type: disk
name: default
used_by:
- /1.0/instances/lxd-ubu2004x01
```
```bash
$ lxc exec lxd-ubu2004x01 -- /bin/bash
root@lxd-ubu2004x01:~# df -h /
Filesystem             Size  Used Avail Use% Mounted on
/dev/vg_vm01/lv_lxd01  100G  1.1G   98G   2% /
```
```bash
root@lxd-ubu2004x01:~# dpkg -l | grep ssh
ii  libssh-4:amd64                 0.9.3-2ubuntu2.1                  amd64        tiny C SSH library (OpenSSL flavor)
ii  openssh-client                 1:8.2p1-4ubuntu0.1                amd64        secure shell (SSH) client, for secure access to remote machines
ii  openssh-server                 1:8.2p1-4ubuntu0.1                amd64        secure shell (SSH) server, for secure access from remote machines
ii  openssh-sftp-server            1:8.2p1-4ubuntu0.1                amd64        secure shell (SSH) sftp server module, for SFTP access from remote machines
ii  ssh-import-id                  5.10-0ubuntu1                     all          securely retrieve an SSH public key and install it locally
```
```bash
root@lxd-ubu2004x01:~# curl http://www.goo.ne.jp/
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>301 Moved Permanently</title>
</head><body>
<h1>Moved Permanently</h1>
<p>The document has moved <a href="https://www.goo.ne.jp/">here</a>.</p>
</body></html>
root@lxd-ubu2004x01:~# 
root@lxd-ubu2004x01:~# exit
$ 
```
