# About the Docker image

This image is built on a version of the Ubuntu base image. See https://hub.docker.com/_/ubuntu/

This image should contain everything needed to develop extension packs for VirtualBox, the open source cross-platform virtualization software maintained by Oracle at https://www.virtualbox.org. It contains an already-compiled working copy of the SVN trunk at https://www.virtualbox.org/svn/vbox/trunk/ and has also precompiled the "example" extension packs included in the code base.

The reason why I wrote this Dockerfile was because the development of extension packs for VirtualBox **apparently** requires the entire VirtualBox code base to be built as well. Setting up the necessary development environment for that turned out to be a fairly complex process and I wanted to automate that, so I could have a Docker base image which would allow me to start developing extensions packs right away and also to have them automatically compiled by CI build servers such as Travis CI (and perhaps eventually also AppVeyor).

Currently, this project allows extension packs to be compiled for 64-bit Linux platforms only. The next step will be to add support for building for macOS as well. Ultimately, I intend to add a Docker image for building extension packs for the Windows version of VirtualBox as well, but that will require AppVeyor to support Windows Server 2016, since that is required for Windows-native Docker containers to be supported.

Also, I still need to figure out how exactly one bundles and packages a single cross-platform extension pack, just like Oracle managed to do with its closed-source extension pack. I have yet to find any documentation on this specificly. If anyone reading this could help me out with any of this, it would be much appreciated. :-)
