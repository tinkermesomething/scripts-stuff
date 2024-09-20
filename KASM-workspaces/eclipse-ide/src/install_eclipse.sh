#!/usr/bin/env bash
set -ex

# Install Eclipse
ECLIPSE_VERSION="2023-06"
ECLIPSE_URL="https://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/${ECLIPSE_VERSION}/R/eclipse-java-${ECLIPSE_VERSION}-R-linux-gtk-x86_64.tar.gz&r=1"

wget -O eclipse.tar.gz "${ECLIPSE_URL}"
tar -xzf eclipse.tar.gz -C /opt/
rm eclipse.tar.gz

# Create Desktop directory if it doesn't exist
mkdir -p /home/kasm-default-profile/Desktop/

# Create Eclipse desktop file
cat << EOF > /usr/share/applications/eclipse.desktop
[Desktop Entry]
Type=Application
Name=Eclipse
Comment=Eclipse Integrated Development Environment
Icon=/opt/eclipse/icon.xpm
Exec=/opt/eclipse/eclipse
Terminal=false
Categories=Development;IDE;Java;
EOF

# Copy the desktop file to the Desktop
cp /usr/share/applications/eclipse.desktop /home/kasm-default-profile/Desktop/
chmod +x /home/kasm-default-profile/Desktop/*.desktop

# Create a workspace directory
mkdir -p /home/kasm-user/workspace
chown -R 1000:0 /home/kasm-user/workspace

# Cleanup for app layer
chown -R 1000:0 /home/kasm-default-profile
find /usr/share/ -name "icon-theme.cache" -exec rm -f {} \;
if [ -z ${SKIP_CLEAN+x} ]; then
  apt-get autoclean
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*
fi
