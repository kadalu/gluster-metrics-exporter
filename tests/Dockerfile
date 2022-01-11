FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -yq &&                                                 \
    apt-get install -y --no-install-recommends python3 libtirpc3 init     \
    vim python3-pip ssh rsync lvm2 less emacs software-properties-common  \
    sudo curl wget git build-essential automake autoconf automake libtool \
    flex bison libssl-dev pkg-config uuid-dev acl-dev zlib1g-dev          \
    libxml2-dev libxml2-utils liburcu-dev xfsprogs gdb attr               \
    libgoogle-perftools-dev zfsutils-linux screen libsqlite3-dev sqlite3  \
    glusterfs-server

RUN echo "root:kadalu" | chpasswd

RUN sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config \
  && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/'       \
    /etc/ssh/sshd_config &&                                                   \
  sed -i.save -e "s#udev_sync = 1#udev_sync = 0#"                             \
    -e "s#udev_rules = 1#udev_rules = 0#"                                     \
    -e "s#use_lvmetad = 1#use_lvmetad = 0#"                                   \
    -e "s#obtain_device_list_from_udev = 1#obtain_device_list_from_udev = 0#" \
    /etc/lvm/lvm.conf &&                                                      \
  systemctl mask getty.target

RUN curl -fsSL https://crystal-lang.org/install.sh | sudo bash

cmd ["/usr/sbin/init"]