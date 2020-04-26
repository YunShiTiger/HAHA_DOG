### 安装gcc

#### 下载

```
wget https://ftp.gnu.org/gnu/gcc/gcc-5.4.0/gcc-5.4.0.tar.bz2
```

#### 解压

```
tar -jxvf gcc-5.4.0.tar.bz2
```

#### 进入目录

```
cd gcc-build-5.4.0
```

#### 执行下载依赖

```
./contrib/download_prerequisites
```

#### 建立一个文件夹存放编译文件

```
mkdir build
```

```
cd build
```

#### 编译并安装

```
../configure --enable-checking=release --enable-languages=c,c++ --disable-multilib
```

```
make && make install
```

#### 验证版本

```
gcc -v
```

#### 解决`GLIBCXX_3.4.21' not found

##### 查看当前库版本

```
strings /lib64/libstdc++.so.6 | grep GLIBC
```

##### 查找

```
find / -name "libstdc++.so*"
```

##### 把新版本库文件贴入

```
cp /usr/local/src/gcc-5.4.0/gcc-build-5.4.0/stage1-x86_64-unknown-linux-gnu/libstdc++-v3/src/.libs/libstdc++.so.6.0.21 /usr/lib64/
```

##### 切换工作目录至/usr/lib64

```
cd /usr/lib64
```

##### 删除原来的软连接

```
rm -rf libstdc++.so.6
```

##### 建立新连接

```
ln -s libstdc++.so.6.0.21 libstdc++.so.6
```

