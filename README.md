sha512s on PKGBUILD must be updated

ztnet.install should be updated to point 'sudo -u POSTGRES_SUPER_USER' or something instead of "sudo -u postgres".

ztnet.install operations regarding stoping or starting systemd service seems to be broken, specially on pre/post_upgrade
