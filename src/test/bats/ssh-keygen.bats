#! /usr/bin/env bats

load utils
source $LUCI_ROOT/functions/ssh-keys

@test "generateSshKey function" {

    local tmpdir=$(tempdir)
    generateSshKey $tmpdir "SSH-key-for-LUCI"

    [ -f $tmpdir/id_rsa.pub ]
    [ -f $tmpdir/id_rsa ]

    echo "Generated in folder $tmpdir"
}

teardown() {
  cleanup_perform
}
