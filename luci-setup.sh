# Source this file to work in the Luci project

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
