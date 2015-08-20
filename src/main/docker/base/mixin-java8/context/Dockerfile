FROM luci/base:0.2

RUN curl -L -k -b "oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u60-b27/server-jre-8u60-linux-x64.tar.gz | gunzip -c | tar x
RUN mkdir -p /luci/mixins && mv /jdk1.8.0_60 /luci/mixins/java
VOLUME /luci/mixins/java
