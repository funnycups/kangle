#!/bin/bash
center_print() {
    input=$1
    IFS=$'\n' read -rd '' -a lines <<< "$input"
    terminal_width=$(tput cols)
    for text in "${lines[@]}"; do
        text_length=${#text}
        leading_spaces=$(( (terminal_width - text_length) / 2 ))
        padding=$(printf '%*s' "$leading_spaces")
        echo "${padding}${text}"
    done
}
center_print "=============================================================
Kangle one click installation
Install kangle web server 3.6.0, MySQL, PHP and PHPMyAdmin.
By default, kangle would be built with http3, kwebp and kwaf support, and PHP5.6, PHP7.4 and PHP8.3 are going to be installed.
More detailed information at
https://www.xh-ws.com/archives/install_kangle_on_ubuntu.html
============================================================="
echo
#get password
read -p "Please enter your desired MySQL password. It must be at least 8 characters long and include numbers, both uppercase and lowercase letters, special characters, and not be a common dictionary word:" mysql_password

#install essentials
apt install -y git cmake make curl wget zip unzip build-essential zlib1g zlib1g-dev libssl-dev\
libevent-dev libjpeg-dev libpng-dev libtiff-dev pkg-config autoconf bison re2c libxml2-dev libsqlite3-dev\
libcurl4-gnutls-dev libfreetype-dev libonigdev

#download zstd
cd ~
mkdir -p install
cd install
git clone https://github.com/facebook/zstd

#install brotli 1.0.9
cd ~/install
wget https://github.com/google/brotli/archive/refs/tags/v1.0.9.tar.gz -O brotli.tar.gz
tar zxf brotli.tar.gz
rm -rf brotli.tar.gz
cd brotli
mkdir out
cd out
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF ..
cmake --build . --config Release --target install

#install pcre
cd ~/install
wget jaist.dl.sourceforge.net/project/pcre/pcre/8.45/pcre-8.45.tar.gz?viasf=1 -O pcre.tar.gz
tar zxf pcre.tar.gz
rm -rf pcre.tar.gz
cd pcre-8.45
mkdir build
cd build
cmake -DCMAKE_C_FLAGS=-fPIC DCMAKE_CXX_FLAGS=-fPIC ..
make && make install

#install kangle
cd ~/install
git clone https://github.com/litespeedtech/lsquic
cd lsquic && git submodule update --init --recursive
cd ~/install
git clone https://github.com/google/boringssl
git clone https://github.com/keengo99/kangle
cd kangle
git submodule update --init --recursive
mkdir build
cd build
mkdir -p /vhs/kangle
cmake -DCMAKE_INSTALL_PREFIX=/vhs/kangle -DZSTD_DIR=~/install/zstd -DENABLE_BROTLI=ON -DBORINGSSL_DIR=~/install/boringssl -DLSQUIC_DIR=~/install/lsquic ..
make && make install

#set service
echo "[Unit]
Description=Kangle Web Server
After=network.target
[Service]
ExecStart=/vhs/kangle/bin/kangle
ExecStop=/vhs/kangle/bin/kangle -q
ExecReload=/vhs/kangle/bin/kangle -r
Restart=on-failure
Type=forking
[Install]
WantedBy=multi-user.target">/etc/systemd/system/kangle.service
systemctl daemon-reload
systemctl enable kangle

#install kwebp
cd ~/install
git clone https://github.com/webmproject/libwebp
cd libwebp
mkdir build && cd build
cmake .. -D CMAKE_C_FLAGS=-fPIC
make && make install
cd ~/install
git clone https://github.com/keengo99/kwebp
cd kwebp
mkdir build && cd build
cmake .. -DKANGLE_DIR=/vhs/kangle -DLIBWEBP_DIR=~/install/libwebp
make
make install

#install kwaf
cd ~/install
git clone https://github.com/keengo99/kwaf
cd kwaf
sed -i "s/set(CMAKE_INSTALL_PREFIX \${KANGLE_DIR})//" CMakeLists.txt
mkdir build && cd build
cmake .. -DKANGLE_DIR=~/install/kangle -DCMAKE_INSTALL_PREFIX=/vhs/kangle
make
make install

#install MySQL
apt install -y mysql-server
mysql<<EOF
UPDATE user SET plugin='mysql_native_password' WHERE User='root';
flush privileges;
ALTER USER root@localhost IDENTIFIED WITH mysql_native_password BY '$mysql_password';
flush privileges;
exit;
EOF

#install PHP
add-apt-repository ppa:ondrej/php
apt install -y php{5.6,7.4,8.3} php{5.6,7.4,8.3}-{cgi,fpm,curl,mysql,gd,xml,mbstring,zip,intl,soap,bcmath,opcache,gmagick,common,memcached,mcrypt,redis,apcu,ldap}

#install PHPMyAdmin
cd /vhs/kangle
mkdir -p nodewww
cd nodewww
wget https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip
unzip phpMyAdmin-5.2.1-all-languages.zip
rm -rf phpMyAdmin-5.2.1-all-languages.zip
mv phpMyAdmin-5.2.1-all-languages mysql

#set index page
cd /vhs/kangle
mkdir -p www
cd www
wget -O index.html https://oss.xh-ws.com

#set etc config
cd /vhs/kangle/etc
wget -O config.xml https://raw.githubusercontent.com/funnycups/kangle/main/config.xml

#start Kangle
systemctl start kangle

center_print "=============================================================
All done!
You can now visit kangle panel through http://127.0.0.1:3311
PHPMyAdmin is at http://127.0.0.1:3313/mysql
Your mysql root password is $mysql_password
Please feel free to report any issue!
============================================================="
