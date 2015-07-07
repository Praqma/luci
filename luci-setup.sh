# Source this file to work in the Luci project

# Attempt to detect the location of this file
# In bash $0 is bash when source from shell, otherwise it is the file sourcing this file. $BASH_SOURCE is set to this file
# In zsh it is the path to this file.
# Other shells has not been tested
if [ -n "$BASH_SOURCE" ] ; then
    f=$BASH_SOURCE
else
    # Assume zsh
    f=$0
fi
dir=$(dirname $f)
# The (cd $dir ; pwd) prints absolute path for $dir. Do the cd with sh, in other shells (e.g. zsh) cd can have other
# side effects
export LUCI_ROOT=${LUCI_ROOT:-$(sh -c "(cd $dir ; pwd)")}
echo "LUCI_ROOT set to '$LUCI_ROOT'. Root of the Luci project source."

if type boot2docker > /dev/null 2>&1 ; then
    usingBoot2docker=true
else
    usingBoot2docker=false
fi

export LUCI_CONFIG=${LUCI_CONFIG:-~/.luci}
echo "LUCI_CONFIG set to '$LUCI_CONFIG'. Configuration for Luci."

export LUCI_DATA=${LUCI_DATA:-~/.luci_data}
echo "LUCI_DATA set to '$LUCI_DATA'. Internal data."

if [ -z "$LUCI_DOCKER_HOST" ] ; then
    if [ $usingBoot2docker = 'true' ] ; then
        LUCI_DOCKER_HOST=$(boot2docker ip)
    else
        echo "--------"
        echo "ERROR : You need to specify your host ip in LUCI_DOCKER_HOST, then try again..."
        echo "eg. export LUCI_DOCKER_HOST=<host-ip>"
        echo "--------"
    fi
fi
export LUCI_DOCKER_HOST
echo "LUCI_DOCKER_HOST set to '$LUCI_DOCKER_HOST'. Docker host for executing local docker containers"

if [ -z "$LUCI_DOCKER_PORT" ] ; then
    if [ $usingBoot2docker = 'true' ] ; then
        #TODO see boot2docker issue in README.md
        # Would be nice with a better solution
        LUCI_DOCKER_PORT=2375
    fi
fi
export LUCI_DOCKER_PORT=${LUCI_DOCKER_PORT:-2375}
echo "LUCI_DOCKER_PORT set to '$LUCI_DOCKER_PORT'. Port for Docker daemon for executing local containers"

if [ $usingBoot2docker = 'true' ] ; then
    : ${LUCI_B2D_WORKAROUND_WITH_SOCAT:=true}
fi
if [ -n "$LUCI_B2D_WORKAROUND_WITH_SOCAT" ] ; then
    echo "LUCI_B2D_WORKAROUND_WITH_SOCAT set to '$LUCI_B2D_WORKAROUND_WITH_SOCAT'. If true a container is started that makes boot2docker listen on port 2375 without TLS"
    export LUCI_B2D_WORKAROUND_WITH_SOCAT
fi

$LUCI_ROOT/bin/boot2dockerFix
