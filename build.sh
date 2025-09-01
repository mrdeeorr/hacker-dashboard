
#!/bin/bash
set -e

PKG_DIR=hacker-dashboard-deb
mkdir -p $PKG_DIR/DEBIAN
mkdir -p $PKG_DIR/usr/local/bin

cat > $PKG_DIR/DEBIAN/control <<EOF
Package: hacker-dashboard
Version: 1.0
Section: utils
Priority: optional
Architecture: all
Maintainer: You <you@example.com>
Description: Hacker Dashboard for Termux
EOF

cp hacker-dashboard.sh $PKG_DIR/usr/local/bin/hacker-dashboard
chmod 755 $PKG_DIR/usr/local/bin/hacker-dashboard

chmod 755 $PKG_DIR/DEBIAN
dpkg-deb --build $PKG_DIR
mv hacker-dashboard-deb.deb hacker-dashboard.deb
