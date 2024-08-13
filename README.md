# kangle
A shell script to install [kangle web server](https://github.com/keengo99/kangle) on Ubuntu.

This script will build and install kangle, with two versions available:

* kangle 3.6.0 with support for HTTP/3, kwebp, and kwaf.
* kangle 3.5.21.16, using pre-compiled executable files from [here](https://github.com/1265578519/kangle)

[Easypanel](https://github.com/netcccyun/easypanel) will also be automatically installed if you choose to install kangle 3.5.21.16.

Additionally, the script will install MySQL8, PHPMyAdmin and multiple versions of PHP (5.6, 7.4, and 8.3).

Usage:

```shell
wget -q https://raw.githubusercontent.com/funnycups/kangle/main/install.sh && bash install.sh
```
More detail information at https://www.xh-ws.com/archives/install_kangle_on_ubuntu.html

## Changelog
### Jun 27, 2024
- Initial release.

### Jul 26, 2024
- Bug fix.

### Jul 30, 2024
- Add support for kangle 3.5.21.16+easypanel.

### Aug 7, 2024
- Fix bugs related to MySQL installation and configuration.

### Aug 13, 2024
- Add support for boost fcontext.
