FROM mcr.microsoft.com/devcontainers/base:ubuntu

ENV LANG=C.UTF-8

# https://qiita.com/uesyn/items/3d2bcd258c35ca6ef4b7#%E9%96%8B%E7%99%BA%E3%81%AB%E5%88%A9%E7%94%A8%E3%81%99%E3%82%8B%E3%82%B3%E3%83%B3%E3%83%86%E3%83%8A%E3%82%A4%E3%83%A1%E3%83%BC%E3%82%B8
RUN DEBIAN_FRONTEND=noninteractive \
  && apt-get update \
  && apt-get install -y --no-install-recommends systemd \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && find /lib/systemd/system/sysinit.target.wants/ -name "systemd-tmpfiles-setup.service" -delete \
  && echo "ReadKMsg=no" >> /etc/systemd/journald.conf \
  && ln -s "$(which systemd)" /sbin/init
# add metadata, must be done after the squashing
# first tell systemd that it is in docker (it will check for the container env)
# https://systemd.io/CONTAINER_INTERFACE/
ENV container=docker
# systemd exits on SIGRTMIN+3, not SIGTERM (which re-executes it)
# https://bugzilla.redhat.com/show_bug.cgi?id=1201657
STOPSIGNAL SIGRTMIN+3

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
      dbus \
      tzdata \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

RUN apt-get update \
  && apt-get install -y --no-install-recommends ansible \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/sbin/init"]
