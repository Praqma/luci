# TODO fix to use debian:jessie
FROM ubuntu:14.04

RUN apt-get update && apt-get install -y python-dev python-setuptools libffi-dev \
            libssl-dev ca-certificates openssh-client wget curl && apt-get clean \
    && easy_install pip \
    && pip install python-openstackclient python-novaclient \
           python-swiftclient python-heatclient python-cinderclient python-keystoneclient \
           python-neutronclient python-designateclient \
    && pip install -U docker-compose

# Install docker-machine
RUN mkdir /root/bin && wget -q https://github.com/docker/machine/releases/download/v0.3.0/docker-machine_linux-amd64 -O /root/bin/docker-machine

ENV DOCKER_VERSION 1.7.0
# Install client. We use the --since flag on docker logs, and it only works in Docker 1.7.0 and upwards 
RUN wget -q https://get.docker.com/builds/Linux/x86_64/docker-$DOCKER_VERSION -O /root/bin/docker && chmod +x /root/bin/* 

ADD entrypoint.sh /entrypoint.sh

# Add luci bins to /root/bin
ENV PATH=/root/bin:$PATH
ADD bin /root/bin

VOLUME /root/.docker
VOLUME /config

# Symlink .bashrc for customizing bash
RUN ln -sf /config/bashrc /root/.bashrc

ENTRYPOINT ["/entrypoint.sh"]
