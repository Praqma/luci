#! /usr/bin/env bats

load utils
source $LUCI_ROOT/functions/ssh-keys
source $LUCI_ROOT/functions/utility-functions

@test "generateSshKey function" {

    local tmpdir=$(tempdir)
    generateSshKey $tmpdir "SSH-key-for-LUCI"

    [ -f $tmpdir/id_rsa.pub ]
    [ -f $tmpdir/id_rsa ]

    echo "Generated in folder $tmpdir"
}

@test "Create ssh key data container" {
    local n=$(uniqueName)
    createSecretKeysContainer $n 
    # The $keyPath in the container contains id_rsa and id_rsa.pub. TODO smarter verification that verifies both files
    docker run --volumes-from $n --rm busybox ls $keyPath | grep id_rsa
}
