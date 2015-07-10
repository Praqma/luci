# This Dockerfile is used to build an image containing basic stuff to be used as a Jenkins slave build node.
FROM java:openjdk-8-jdk
MAINTAINER Praqma.net <info@praqma.net>

# Make sure the package repository is up to date.
RUN apt-get update && apt-get -y upgrade

# Install a basic SSH server
RUN apt-get install -y openssh-server
RUN sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd
RUN mkdir -p /var/run/sshd

RUN mkdir ~/.ssh && chmod 700 ~/.ssh
RUN ln -s /data/server-keys/authorized_keys ~/.ssh/authorized_keys

USER root
# Standard SSH port
EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
