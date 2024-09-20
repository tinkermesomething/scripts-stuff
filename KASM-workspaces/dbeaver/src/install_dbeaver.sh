#!/usr/bin/env bash
set -ex
START_COMMAND="/usr/bin/dbeaver"
PGREP="dbeaver"
export MAXIMIZE="true"
export MAXIMIZE_NAME="DBeaver"
MAXIMIZE_SCRIPT=$STARTUPDIR/maximize_window.sh
DEFAULT_ARGS=""
ARGS=${APP_ARGS:-$DEFAULT_ARGS}

kasm_exec() {
    if [ -n "$KASM_URL" ] ; then
        URL=$KASM_URL
    elif [ -z "$URL" ] ; then
        URL=$LAUNCH_URL
    fi

    # Since DBeaver doesn't take a URL as an argument, we ignore it
    /usr/bin/filter_ready
    /usr/bin/desktop_ready
    bash ${MAXIMIZE_SCRIPT} &
    $START_COMMAND $ARGS
}

kasm_startup() {
    if [ -z "$DISABLE_CUSTOM_STARTUP" ] ; then
        echo "Entering process startup loop"
        set +x
        while true
        do
            if ! pgrep -x $PGREP > /dev/null
            then
                /usr/bin/filter_ready
                /usr/bin/desktop_ready
                set +e
                bash ${MAXIMIZE_SCRIPT} &
                $START_COMMAND $ARGS
                set -e
            fi
            sleep 1
        done
        set -x
    fi
}

if [ -n "$GO" ] || [ -n "$ASSIGN" ] ; then
    kasm_exec
else
    kasm_startup
fi
root@DEB64-Docker01:/opt/dbeaver-image# ^C
root@DEB64-Docker01:/opt/dbeaver-image# cat src/install_dbeaver.sh
#!/usr/bin/env bash
set -ex

# Install DBeaver
wget -O - https://dbeaver.io/debs/dbeaver.gpg.key | apt-key add -
echo "deb https://dbeaver.io/debs/dbeaver-ce /" | tee /etc/apt/sources.list.d/dbeaver.list
apt-get update
apt-get install -y dbeaver-ce

# Create Desktop directory if it doesn't exist
mkdir -p /home/kasm-default-profile/Desktop/

# Find and copy the DBeaver desktop file
DBEAVER_DESKTOP=$(find /usr/share/applications -name "*dbeaver*.desktop" | head -n 1)
if [ -n "$DBEAVER_DESKTOP" ]; then
    cp "$DBEAVER_DESKTOP" /home/kasm-default-profile/Desktop/
    chmod +x /home/kasm-default-profile/Desktop/*.desktop
else
    echo "DBeaver desktop file not found. Skipping desktop shortcut creation."
fi

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
