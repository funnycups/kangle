# kangle
A shell script to install [kangle web server](https://github.com/keengo99/kangle) on Ubuntu/Debian.

This script builds and installs kangle, offering three options:

1. kangle 3.6.0 with support for HTTP/3, kwebp, and kwaf.
2. kangle 3.5.21.16 with [Easypanel](https://github.com/netcccyun/easypanel), using pre-compiled executable files from [this repository](https://github.com/1265578519/kangle)
3. kangle 3.5.21.16 in Docker with Easypanel, kwebp, kwaf, and TLS-enabled Pure-FTPd

Additionally, the script will install MySQL8, PHPMyAdmin and multiple PHP versions:
- PHP 5.6, 7.4, and 8.3.

Usage:

```shell
wget -q -O install.sh https://raw.githubusercontent.com/funnycups/kangle/main/install.sh && bash install.sh
```
More detail information at https://www.cups.moe/archives/install-kangle-on-ubuntu-debian.html

## Changelog
### Jun 2, 2025
- Install docker following the official guide.
- Fix random password set up.

### May 15, 2025
- Fix random password for docker installation.

### May 13, 2025
- Fix docker container setup.

### Mar 24, 2025
- Generate random password instead of default `kangle` for panel.

### Mar 15, 2025
- Enable MySQL socket connection for docker installation.

### Mar 14, 2025
- Bug fix for Docker installation and Pure-FTPd TLS error.
- Docker installation now install PHP7.4 instead of PHP7.2.
- Docker installation now run Easypanel under PHP7.4 instead of PHP5.6, which should solve problems on MySQL8 connection.
- Refactor the project directory structure for better clarity and organization.
- Synchronize container time with host time.
- Save vhost configuration files in the host directory for easy access and backup.

### Dec 7, 2024
- Add docker support.

### Nov 10, 2024
- Add Debian support.

### Nov 4, 2024
- Bug fix for php-mysql and PHPMyAdmin.

### Aug 13, 2024
- Add support for boost fcontext.

### Aug 7, 2024
- Fix bugs related to MySQL installation and configuration.

### Jul 30, 2024
- Add support for kangle 3.5.21.16+easypanel.

### Jul 26, 2024
- Bug fix.

### Jun 27, 2024
- Initial release.
