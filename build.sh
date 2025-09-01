<<<<<<< HEAD

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
=======
#!/bin/bash

# Package name and version
PKG_NAME="hacker-dashboard"
PKG_VERSION="1.0"

# Clean old build
rm -rf ${PKG_NAME}-deb
mkdir -p ${PKG_NAME}-deb/DEBIAN
mkdir -p ${PKG_NAME}-deb/data/data/com.termux/files/usr/bin

# Create control file
cat <<EOF > ${PKG_NAME}-deb/DEBIAN/control
Package: ${PKG_NAME}
Version: ${PKG_VERSION}
Architecture: all
Maintainer: mrdeeorr <your_email@example.com>
Depends: curl, nmap, openssh, apache2, exploitdb
Description: All-in-One Hacker Dashboard for Termux with auto-update, scanning, payload generation, and server tools.
EOF

# Copy your script into bin directory
cp hacker-dashboard.sh ${PKG_NAME}-deb/data/data/com.termux/files/usr/bin/${PKG_NAME}
chmod +x ${PKG_NAME}-deb/data/data/com.termux/files/usr/bin/${PKG_NAME}

# Fix permissions
chmod 755 ${PKG_NAME}-deb/DEBIAN

# Build the .deb package
dpkg-deb --build ${PKG_NAME}-deb

# Rename output for convenience
mv ${PKG_NAME}-deb.deb ${PKG_NAME}.deb

echo "✅ Build complete: ${PKG_NAME}.deb"
echo "👉 Install with: dpkg -i ${PKG_NAME}.deb"
>>>>>>> 804b373a610ac88e0fde0c4a91ed1c61605b4619
