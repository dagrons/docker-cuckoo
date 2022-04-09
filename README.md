# cuckoo环境搭建

cuckoo已经没有维护了，现在的cuckoo必须经过修改才能正常编译，自定义了一个docker-cuckoo，可以用来方便地编译cuckoo环境

由于之前的版本都比较奇怪，重新打包一个新的docker-cuckoo，分支是pve

先装个干净的ubuntu，设置一个普通用户（不能是root），推荐设置为dell，密码1205

设置好透明代理

```shell
ip r del default 
ip r add default via 10.112.108.112 # 这里替换为透明代理网关
```

然后执行
```shell
sudo su # 切换到root
wget -qO- https://gist.githubusercontent.com/dagrons/256a423e7fb8390f934dc191e37fe5a5/raw/892cfe48129d29faac6e0ac217cd082015d85de7/install_docker-cuckoo.sh | bash
```

执行后，会提示创建cuckoo_infant1后再继续，其实就是在virtualbox中为cuckoo1创建命名为cuckoo1_infant的快照

再执行

```shell
wget -qO- https://gist.githubusercontent.com/dagrons/256a423e7fb8390f934dc191e37fe5a5/raw/892cfe48129d29faac6e0ac217cd082015d85de7/install_docker-cuckoo.sh| bash -s continue
```
