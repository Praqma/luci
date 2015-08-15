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

export LUCI_CONFIG=${LUCI_CONFIG:-~/.luci}
echo "LUCI_CONFIG set to '$LUCI_CONFIG'. Configuration for Luci."

export LUCI_DATA=${LUCI_DATA:-~/.luci_data}
echo "LUCI_DATA set to '$LUCI_DATA'. Internal data."

if [ -z "$LUCI_DOCKER_HOST" ] ; then
    echo "--------"
    echo "ERROR : You need to specify your host ip in LUCI_DOCKER_HOST, then try again..."
    echo "eg. export LUCI_DOCKER_HOST=<host-ip>"
    echo "--------"
fi
export LUCI_DOCKER_HOST
echo "LUCI_DOCKER_HOST set to '$LUCI_DOCKER_HOST'. Docker host for executing local docker containers"

export LUCI_DOCKER_PORT=${LUCI_DOCKER_PORT:-2375}
echo "LUCI_DOCKER_PORT set to '$LUCI_DOCKER_PORT'. Port for Docker daemon for executing local containers"

if [ $usingBoot2docker = 'true' ] ; then
    : ${LUCI_B2D_WORKAROUND_WITH_SOCAT:=true}
fi

