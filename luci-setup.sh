# Source this file to work in the Luci project

export LUCI_CONFIG=${LUCI_CONFIG:-~/.luci}
echo "LUCI_CONFIG set to '$LUCI_CONFIG'"

local dir=$(dirname $0)
# The (cd $dir ; pwd) prints absolute path for $dir. Do the cd with sh, in other shells (e.g. zsh) cd can have other
# side effects
export LUCI_ROOT=$(sh -c "(cd $dir ; pwd)")
echo "LUCI_ROOT set to '$LUCI_ROOT'"
