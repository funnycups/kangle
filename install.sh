#!/bin/bash
center_print() {
	input=$1
	IFS=$'\n' read -rd '' -a lines <<<"$input"
	terminal_width=$(tput cols)
	for text in "${lines[@]}"; do
		text_length=${#text}
		leading_spaces=$(((terminal_width - text_length) / 2))
		padding=$(printf '%*s' "$leading_spaces")
		echo "${padding}${text}"
	done
}
system_warn() {
	RED='\033[0;31m'
	NC='\033[0m'
	echo -e "${RED}${1}${NC}"
}
center_print "=============================================================
Kangle one click installation
This script will build and install kangle.
Easypanel, MySQL8, PHPMyAdmin and multiple versions of PHP would be installed.
More detailed information at
https://www.cups.moe/archives/install-kangle-on-ubuntu-debian.html
============================================================="
echo
if [ -f /etc/os-release ]; then
	. /etc/os-release
	if [ "$ID" = "ubuntu" ]; then
		os="ubuntu"
		echo "Ubuntu detected."
	elif [ "$ID" = "debian" ]; then
		os="debian"
		echo "Debian detected"
	else
		os="other"
		system_warn "Error: You are not using Debian or Ubuntu. Installation may not succeed. Press Enter to continue or Ctrl+C to cancel."
		read confirm
	fi
else
	os="other"
	system_warn "Error: Unable to confirm your operating system. Installation may not succeed. Press Enter to continue or Ctrl+C to cancel."
	read confirm
fi
#get password
read -p "Please enter your desired MySQL password. It must be at least 8 characters long and include numbers, both uppercase and lowercase letters, special characters, and not be a common dictionary word.
Leave blank to not install MySQL:" mysql_password

read -p "Version:
1)kangle 3.6.0 with support for HTTP/3, kwebp, and kwaf
2)kangle 3.5.21.16 with Easypanel
3)kangle 3.5.21.16 in Docker with Easypanel, kwebp, kwaf, and TLS-enabled Pure-FTPd
Please select a version of kangle you would like to install:" kangle_ver
if [[ $kangle_ver != 1 && $kangle_ver != 2 && $kangle_ver != 3 ]]; then
	echo "Unknown input!"
	exit 1
fi
#install essentials
sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf
apt update -y
apt install -y git cmake make curl wget zip unzip build-essential zlib1g zlib1g-dev libssl-dev libevent-dev libjpeg-dev libpng-dev libtiff-dev pkg-config autoconf bison re2c libxml2-dev libsqlite3-dev libcurl4-gnutls-dev libfreetype-dev libonig-dev

cd ~
mkdir -p install
cd install
if [[ $kangle_ver != 3 ]]; then
	#download zstd
	git clone https://github.com/facebook/zstd

	#install brotli 1.0.9
	cd ~/install
	wget https://github.com/google/brotli/archive/refs/tags/v1.0.9.tar.gz -O brotli.tar.gz
	tar zxf brotli.tar.gz
	rm -rf brotli.tar.gz
	cd brotli-1.0.9
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
	#generate default password for panel
  password=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9!@#$%^&*()' | head -c 16)
  password_md5=$(echo -n "$password" | md5sum | awk '{print $1}')
	cd ~/install
	if [[ $kangle_ver == 1 ]]; then
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
		cmake -DCMAKE_INSTALL_PREFIX=/vhs/kangle -DZSTD_DIR=~/install/zstd -DENABLE_BROTLI=ON -DBORINGSSL_DIR=~/install/boringssl -DLSQUIC_DIR=~/install/lsquic -DENABLE_FCONTEXT=1 ..
		make && make install
	else
		wget https://raw.githubusercontent.com/funnycups/kangle/main/3.5.21.16/kangle-3.5.21.16.tar.gz -O kangle.tar.gz
		tar zxvf kangle.tar.gz
		mkdir -p /vhs/kangle
		cp -rf kangle/* /vhs/kangle
	fi

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
WantedBy=multi-user.target" >/etc/systemd/system/kangle.service
	systemctl daemon-reload
	systemctl enable kangle

	if [[ $kangle_ver == 1 ]]; then
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
	fi
else
	#install docker
	#apt install -y docker.io
	#install docker following official guide
	if [[ $os == "ubuntu" ]]; then
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  else
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  fi
  sudo apt-get update
  apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	systemctl enable --now docker
	#launch kangle images
	docker pull funnycups/kangle
	mkdir -p /home/ftp
	mkdir -p /vhs/kangle
	cd /vhs/kangle
	wget https://raw.githubusercontent.com/funnycups/kangle/main/docker/etc.tar.gz
	tar zxvf etc.tar.gz
	rm -rf etc.tar.gz
	cd -
	if [[ $mysql_password ]]; then
	  #enable socket connection
	  mkdir -p /var/run/mysqld
	  docker create --network host -v /home/ftp:/home/ftp -v /vhs/kangle/etc:/vhs/kangle/etc -v /etc/localtime:/etc/localtime:ro -v /var/run/mysqld:/var/run/mysqld --name kangle --restart unless-stopped funnycups/kangle
	else
	  docker create --network host -v /home/ftp:/home/ftp -v /vhs/kangle/etc:/vhs/kangle/etc -v /etc/localtime:/etc/localtime:ro --name kangle --restart unless-stopped funnycups/kangle
  fi
  docker exec kangle openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -keyout /vhs/pure-ftpd/etc/ssl/private/pure-ftpd.pem -out /vhs/pure-ftpd/etc/ssl/private/pure-ftpd.pem -subj "/C=US/ST=California/L=San Francisco/O=FTP/OU=./CN=."
  docker exec kangle systemctl restart pureftpd
fi
MYSQL_INTRO=
if [[ $mysql_password ]]; then
	#install MySQL
	if [[ $os == "ubuntu" ]]; then
	  #compatible with docker image
	  sql=""
	  if [[ $kangle_ver == 3 ]]; then
      sql="ALTER USER root@127.0.0.1 IDENTIFIED WITH mysql_native_password BY '$mysql_password';"
    fi
		apt install -y mysql-server
		mysql <<EOF
USE mysql;
UPDATE user SET plugin='mysql_native_password' WHERE User='root';
flush privileges;
ALTER USER root@localhost IDENTIFIED WITH mysql_native_password BY '$mysql_password';
$sql
flush privileges;
exit;
EOF
	else
	  sql=""
	  if [[ $kangle_ver == 3 ]]; then
      sql="ALTER USER root@127.0.0.1 IDENTIFIED BY '$mysql_password';"
    fi
		apt install -y mariadb-server
		mysql <<EOF
USE mysql;
ALTER USER root@localhost IDENTIFIED BY '$mysql_password';
$sql
flush privileges;
exit;
EOF
	fi

	#install PHPMyAdmin
	if [[ $kangle_ver != 3 ]]; then
		cd /vhs/kangle
		mkdir -p nodewww/dbadmin
		cd nodewww/dbadmin
		wget https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip
		unzip phpMyAdmin-5.2.1-all-languages.zip
		rm -rf phpMyAdmin-5.2.1-all-languages.zip
		mv phpMyAdmin-5.2.1-all-languages mysql
		cd mysql
		mv config.sample.inc.php config.inc.php
	fi

	#enable socket connection
	if [[ $kangle_ver == 3 ]]; then
	  chmod 755 /var/run/mysqld
  fi
	MYSQL_INTRO="PHPMyAdmin is at http://127.0.0.1:3313/mysql
Your mysql root password is $mysql_password
"

fi

if [[ $kangle_ver != 3 ]]; then
	#install PHP
	if [[ $os == "ubuntu" ]]; then
		add-apt-repository ppa:ondrej/php <<EOF

EOF
	else
		apt install -y software-properties-common ca-certificates lsb-release apt-transport-https
		sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
		wget -qO - https://packages.sury.org/php/apt.gpg | apt-key add -
	fi
	apt update
	if [[ $mysql_password ]]; then
		apt install -y php{5.6,7.4,8.3} php{5.6,7.4,8.3}-{cgi,fpm,curl,mysql,gd,xml,mbstring,zip,intl,soap,bcmath,opcache,gmagick,common,memcached,mcrypt,redis,apcu,ldap} php-mbstring
	else
		apt install -y php{5.6,7.4,8.3} php{5.6,7.4,8.3}-{cgi,fpm,curl,gd,xml,mbstring,zip,intl,soap,bcmath,opcache,gmagick,common,memcached,mcrypt,redis,apcu,ldap} php-mbstring
	fi
	#set up easypanel
	EASYPANEL_INTRO=
	if [[ $kangle_ver == 2 ]]; then
		apt install php7.4-sqlite3
		cd ~/install
		wget https://raw.githubusercontent.com/funnycups/kangle/main/3.5.21.16/easypanel-2.6.26.tar.gz -O easypanel.tar.gz
		tar zxvf easypanel.tar.gz
		cd easypanel-2.6.26-x86_64
		cp -rf * /vhs/kangle
		cd /vhs/kangle/nodewww/webftp
		rm -rf *
		git clone https://github.com/netcccyun/easypanel
		mv easypanel/* .
		rm -rf easypanel
		echo 'SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
HOME=/
*/5 * * * * root /bin/php-cgi5.6 -c /etc/php/5.6/cli/php.ini /vhs/kangle/nodewww/webftp/framework/shell.php sync_flow' >/etc/cron.d/ep_sync_flow
		systemctl restart cron
		chattr +i /etc/cron.d/ep_sync_flow
		EASYPANEL_INTRO="Easypanel is at http://127.0.0.1:3312/admin
"
		ln -s /bin/wget /vhs/kangle/bin/
	fi

	#set up index page
	cd /vhs/kangle
	mkdir -p www
	cd www
	wget -O index.html https://raw.githubusercontent.com/funnycups/kangle/main/static/index.html

	#set up etc config
	cd /vhs/kangle/etc
	if [[ $kangle_ver == 1 ]]; then
		wget -O config.xml https://raw.githubusercontent.com/funnycups/kangle/main/3.6.0/config.xml
		#set up random password
		sed -i "s|password='kangle'|password='$password'|g" /vhs/kangle/etc/config.xml
	else
		wget -O config.xml https://raw.githubusercontent.com/funnycups/kangle/main/3.5.21.16/config-3.5.21.16.xml
		cd /vhs/kangle/ext
		wget https://raw.githubusercontent.com/funnycups/kangle/main/3.5.21.16/tpl_php.zip
		unzip -o tpl_php.zip
		rm -rf tpl_php.zip
		#set up random password
    sed -i "s|<admin user=\"admin\" password=\"kangle\" admin_ips=\"127.0.0.1\|\*\"/>|<admin user='admin' password='$password_md5' crypt='md5' auth_type='Basic' admin_ips='*'/>|g" /vhs/kangle/etc/config.xml
	fi

  #start Kangle
	systemctl start kangle
else
	echo 'SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
HOME=/
*/5 * * * * root docker exec kangle /vhs/kangle/ext/tpl_php56/bin/php -c /vhs/kangle/ext/tpl_php52/etc/php-node-5640.ini /vhs/kangle/nodewww/webftp/framework/shell.php sync_flow' >/etc/cron.d/ep_sync_flow
	systemctl restart cron
	EASYPANEL_INTRO="Easypanel is at http://127.0.0.1:3312/admin
"
  #set up random password
  docker exec kangle sed -i "s|<admin user=\"admin\" password=\"kangle\" admin_ips=\"127.0.0.1\|\*\"/>|<admin user='admin' password='$password_md5' crypt='md5' auth_type='Basic' admin_ips='*'/>|g" /vhs/kangle/etc/config.xml
  docker start kangle
fi

#remove temp files
cd ~
rm -rf install

center_print "=============================================================
All done!
You can now visit kangle panel through http://127.0.0.1:3311
${EASYPANEL_INTRO}Username:admin, password:${password}.
${MYSQL_INTRO}Please feel free to report any issue!
============================================================="
