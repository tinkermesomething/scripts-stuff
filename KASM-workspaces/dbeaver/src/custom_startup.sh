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