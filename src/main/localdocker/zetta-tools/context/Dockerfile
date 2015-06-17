FROM ubuntu:14.04

MAINTAINER Praqma <info@praqma.net>

RUN apt-get update && apt-get install -y python-dev python-setuptools libffi-dev \
            libssl-dev ca-certificates openssh-client && apt-get clean \
    && easy_install pip \
    && pip install python-openstackclient python-novaclient \
           python-swiftclient python-heatclient python-cinderclient python-keystoneclient \
           python-neutronclient python-designateclient docker-compose

ENV PATH=/root/bin:$PATH

ADD entrypoint.sh /entrypoint.sh
ADD bin /root/bin

VOLUME /root/.docker/machine
VOLUME /config

# Symlink .bashrc for customizing bash
RUN ln -sf /config/bashrc /root/.bashrc

ENTRYPOINT ["/entrypoint.sh"]
