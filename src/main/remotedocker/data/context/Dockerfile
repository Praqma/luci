FROM scratch

# Volume with ssh server keys (essentially authorized_keys) so clients can access the container by private/public key authentication
# We don't wont to mount the client keys (public and private). If done
# it would mean every container has access to the private keys
VOLUME /data/server-keys

# User home for gradle builds
VOLUME /data/gradle-user-home

# Jenkins home as a volume
VOLUME /var/jenkins_home

# Artifactory volumes
VOLUME /luci/artifactory/data
VOLUME /luci/artifactory/backup

CMD not possible to run this container
