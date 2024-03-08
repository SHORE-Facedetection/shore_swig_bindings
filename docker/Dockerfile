FROM ubuntu:22.04
MAINTAINER facedetection@iis.fraunhofer.de
RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y \
       sudo \
       build-essential \
       openjdk-8-jdk \
       git \
       cmake \
       libimage-magick-perl \
       swig \
       zip \
       unzip && \
    rm -rf /var/lib/apt/lists/*

ARG ANDROID_NDK=android-ndk-r23b.zip
RUN mkdir -p /opt/cross-compiler/
COPY ${ANDROID_NDK} /opt/cross-compiler
RUN unzip /opt/cross-compiler/${ANDROID_NDK} -d /opt/cross-compiler && \
    rm -f /opt/cross-compiler/${ANDROID_NDK} && \
    ln -sf /opt/cross-compiler/* /opt/cross-compiler/android-ndk

RUN useradd -m dockeruser
RUN chown -R dockeruser /opt && chmod 755 /opt
RUN echo "dockeruser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/dockeruser
USER dockeruser
