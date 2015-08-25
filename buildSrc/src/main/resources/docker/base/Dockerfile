FROM debian:jessie

MAINTAINER info@praqma.net

# Make sure the package repository is up to date.
RUN apt-get update && apt-get -y upgrade

# Installing often used packages
RUN apt-get install -y unzip curl

# Add luci user and set password
RUN useradd -ms /bin/bash -u 5824 luci

