# Copyright 2016 Volkert de Buisonjé \<volkertb@users.noreply.github.com\>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# TODO: Place a question in the VirtualBox forums asking how to package a multi-platform
#       and multi-architecture extension pack inside a single .vbox-extpack file, just
#       like what Oracle did with its Oracle VM VirtualBox Extension Pack.
#
# From the "Preliminary notes:" section in the COPYING file of the VirtualBox code base:
#
# "The GPL listed below does not bind software which uses VirtualBox services by
# merely linking to VirtualBox libraries so long as all VirtualBox interfaces used
# by that software are multi-licensed. A VirtualBox interface is deemed
# multi-licensed if it is declared in a VirtualBox header file that is licensed
# under both the GPL version 2 (below) *and* the Common Development and
# Distribution License Version 1.0 (CDDL), as it comes in the "COPYING.CDDL" file.
# In other words, calling such a multi-licensed interface is merely considered
# normal use of VirtualBox and does not turn the calling code into a derived work
# of VirtualBox. In particular, this applies to code that wants to extend
# VirtualBox by way of the Extension Pack mechanism declared in the ExtPack.h
# header file."
#

FROM ubuntu:16.10

RUN mkdir /tmp/vbox_src
WORKDIR /tmp/vbox_src

RUN apt-get -y update
RUN apt-get -y dist-upgrade
RUN apt-get -y install subversion wget

RUN date

# For some reason, SVN will complain about an "untrusted certificate", until a connection has already been made to the same site (???).
RUN wget https://www.virtualbox.org/svn/vbox/trunk/COPYING

# Download VirtualBox source code from the official SVN repository (trunk) to the working directory:
RUN svn export https://www.virtualbox.org/svn/vbox/trunk/

# === DO NOT EDIT LINES ABOVE THIS LINE, OR SVN EXPORT WILL BE REDONE BY THE DOCKER BUILDER, WHICH TAKES A LONG TIME. ===

RUN rm ./COPYING

# Install this first, to prevent a warning later on.
RUN apt-get -y install apt-utils

# Temporarily set the following environment variable to prevent non-fatal (but ugly and confusing) debconf errors later on.
ENV DEBIAN_FRONTEND_ORIG=${DEBIAN_FRONTEND}
ENV DEBIAN_FRONTEND noninteractive

# Install libsdl1.2-dev first, to prevent a "/bin/sh: 1: libsdl1.2-dev: not found" error while processing triggers for sgml-base later on.
#RUN apt-get -y install libsdl1.2-dev

RUN apt-cache search libhal
RUN apt-cache search python-central

# Apply the Linux build prerequisites laid out at https://www.virtualbox.org/wiki/Linux%20build%20instructions
RUN apt-get -y install gcc g++ bcc iasl xsltproc uuid-dev zlib1g-dev libidl-dev libsdl1.2-dev libxcursor-dev libasound2-dev libstdc++5 libpulse-dev libxml2-dev libxslt1-dev python-dev libqt4-dev qt4-dev-tools libcap-dev libxmu-dev mesa-common-dev libglu1-mesa-dev linux-kernel-headers libcurl4-openssl-dev libpam0g-dev libxrandr-dev libxinerama-dev libqt4-opengl-dev makeself libdevmapper-dev default-jdk texlive-latex-base texlive-latex-extra texlive-latex-recommended texlive-fonts-extra texlive-fonts-recommended
RUN apt-get -y install libc6-dev-i386 lib32gcc1 gcc-multilib lib32stdc++6 g++-multilib
# Add additional dependencies that were apparently also necessary for VirtualBox to build successfully.
RUN apt-get -y install genisoimage
RUN apt-get -y install libssl-dev
RUN apt-get -y install libvpx-dev
RUN apt-cache search qt5 | grep -i dev
RUN apt-get -y install qtbase5-dev qtbase5-dev-tools libqt5opengl5-dev
RUN apt-get -y install linux-headers-generic
# ==== DO NOT CHANGE ANYTHING ABOVE THIS LINE, OTHER THAN COMMENTS. ====
RUN mkdir /tmp/openwatcom
WORKDIR /tmp/openwatcom
RUN wget ftp://ftp.openwatcom.org/pub/open-watcom-c-linux-1.9
RUN echo "960fe6b5cf88769a42949f5fedf62827 *open-watcom-c-linux-1.9" | md5sum -c
RUN wget ftp://ftp.openwatcom.org/pub/open-watcom-f77-linux-1.9
RUN echo "8985018415fcdc90bab67d1b470f0fa2 *open-watcom-f77-linux-1.9" | md5sum -c
# Necessary step for the Watcom installer to work found at https://groups.google.com/forum/#!topic/openwatcom.contributors/deAetKFRDFk did not work.
# RUN ln -s /lib/terminfo/x /usr/share/terminfo
# ENV TERMINFO=/lib/terminfo
# Could just unzip the file. Found this out from https://forums.virtualbox.org/viewtopic.php?f=10&t=56239
RUN mkdir /opt/openwatcom
WORKDIR /opt/openwatcom
RUN unzip /tmp/openwatcom/open-watcom-c-linux-1.9
#RUN unzip /tmp/openwatcom/open-watcom-f77-linux-1.9
# Set the executable bit on all executable files.
RUN find . -type f -print0 | xargs -0 chmod +x
ENV WATCOM=/opt/openwatcom
WORKDIR /tmp/vbox_src/trunk
RUN ./configure

# TODO: move this up to the "addition dependencies that were apparently...", but AFTER I get the build working (otherwise it would trigger re-downloads in the previous steps again...)
RUN apt-get -y install libqt5x11extras5-dev nasm qttools5-dev-tools

# Build VirtualBox.
RUN /bin/bash -c "source /tmp/vbox_src/trunk/env.sh && kmk"

# Compile the kernel modules.
# (Commented out, because compiling kernel modules specifically for the Docker environment on which VirtualBox is built (but on which it will not be run) is rather pointless.
#WORKDIR ./out/linux.amd64/release/bin/src
#RUN /bin/bash -c "source /tmp/vbox_src/trunk/env.sh && make"

# List any VirtualBox extension packs that have already been built alongn with the main build:
RUN find /tmp/vbox_src/trunk -type f -name "*.vbox-extpack"

# Build the Skeleton extension pack.
WORKDIR /tmp/vbox_src/trunk/src/VBox/ExtPacks/Skeleton/
RUN /bin/bash -c "source /tmp/vbox_src/trunk/env.sh && kmk"
# The build command "kmk packing" packages the extenstion pack in a ready-to-install .vbox-extpack file.
RUN /bin/bash -c "source /tmp/vbox_src/trunk/env.sh && kmk packing"

# Build the BusMouseSample extension pack.
WORKDIR /tmp/vbox_src/trunk/src/VBox/ExtPacks/BusMouseSample/
RUN /bin/bash -c "source /tmp/vbox_src/trunk/env.sh && kmk"
# The build command "kmk packing" packages the extenstion pack in a ready-to-install .vbox-extpack file.
RUN /bin/bash -c "source /tmp/vbox_src/trunk/env.sh && kmk packing"

# To build the VNC extension pack, additional dependencies are required, as is explained at https://forums.virtualbox.org/viewtopic.php?f=1&t=40479.
RUN apt-get -y install libvncserver-dev

# Build the VNC extension pack.
WORKDIR /tmp/vbox_src/trunk/src/VBox/ExtPacks/VNC/
RUN /bin/bash -c "source /tmp/vbox_src/trunk/env.sh && kmk"
# The build command "kmk packing" packages the extenstion pack in a ready-to-install .vbox-extpack file.
RUN /bin/bash -c "source /tmp/vbox_src/trunk/env.sh && kmk packing"

# Now we should find the completed extension packs, packaged as ready-to-use .vbox-extpack files.
RUN find /tmp/vbox_src/trunk -type f -name "*.vbox-extpack"

# Verify that the packaged extension packs are indeed located in the expected location:
RUN ls -lGh tmp/vbox_src/trunk/out/linux.amd64/release/packages/VNC-5.1.51r63759.vbox-extpack
RUN ls -lGh /tmp/vbox_src/trunk/out/linux.amd64/release/packages/BusMouse-5.1.51r63759.vbox-extpack
RUN ls -lGh /tmp/vbox_src/trunk/out/linux.amd64/release/packages/Skeleton-5.1.51r63759.vbox-extpack

# Restore the original debconf environment variable to its original setting, so as not to cause any unexpected behaviour in images that are based on this image.
# ( See also https://docs.docker.com/v1.6/faq/#why-is-debian_frontendnoninteractive-discouraged-in-dockerfiles )
ENV DEBIAN_FRONTEND=${DEBIAN_FRONTEND_ORIG}

# To copy the created files from a Docker container (based on this image) back to the host, type the following command:
# docker cp <containerId>:/tmp/vbox_src/trunk/out/linux.amd64/release/packages/*vbox-extpack /host/path/target # With thanks to https://stackoverflow.com/a/22050116
# To copy the created files from a Docker image back to the host, type the following command for each file (which will temporarily start a container instance to enable copying from it):
# docker run --rm --entrypoint cat yourimage /path/to/file > path/to/destination # With thanks to https://stackoverflow.com/a/34093828