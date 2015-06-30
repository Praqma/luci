# Source this file to work in the Luci project

if type boot2docker > /dev/null 2>&1 ; then
    usingBoot2docker=true
else
    usingBoot2docker=false
fi

export LUCI_CONFIG=${LUCI_CONFIG:-~/.luci}
echo "LUCI_CONFIG set to '$LUCI_CONFIG'. Configuration for Luci."

export LUCI_DATA=${LUCI_DATA:-~/.luci_data}
echo "LUCI_DATA set to '$LUCI_DATA'. Internal data."

# in bash $0 is bash, in zsh it is the path to this file.
# Other shells has not been tested, the following assume behaviour like zsh (for simplicity, not because it is likely)
case $0 in
    bash) f=$BASH_SOURCE ;;
    *) f=$0
esac
dir=$(dirname $f)
# The (cd $dir ; pwd) prints absolute path for $dir. Do the cd with sh, in other shells (e.g. zsh) cd can have other
# side effects
export LUCI_ROOT=$(sh -c "(cd $dir ; pwd)")
echo "LUCI_ROOT set to '$LUCI_ROOT'. Root of the Luci project source."

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
echo "LUCI_DOCKER_PORT set to '$LUCI_DOCKER_PORT'. Its used to contact the Docker hosts Docker daemon over TCP by Jenkins"
