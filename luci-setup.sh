# Source this file to work in the Luci project

export LUCI_CONFIG=${LUCI_CONFIG:-~/.luci}
echo "LUCI_CONFIG is set to '$LUCI_CONFIG'"

export LUCI_ROOT=$(cd "$(dirname "$0")"; pwd)
echo "LUCI_ROOT is set to '$LUCI_ROOT'"
