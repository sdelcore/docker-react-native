# Docker image for react native.

FROM node:8.11.1

MAINTAINER Spencer <https://github.com/sdelcore>


# Setup environment variables
ENV PATH $PATH:node_modules/.bin


# Install Java
RUN apt-get update -q && \
	apt-get install -qy --no-install-recommends python-dev default-jdk


# Install Android SDK

## Set correct environment variables.
#ENV ANDROID_SDK_FILE android-sdk_r26.1.1-linux.tgz
#ENV ANDROID_SDK_URL http://dl.google.com/android/$ANDROID_SDK_FILE
ENV ANDROID_SDK_FILE sdk-tools-linux-3859397.zip
ENV ANDROID_SDK_URL https://dl.google.com/android/repository/$ANDROID_SDK_FILE

## Install 32bit support for Android SDK
RUN dpkg --add-architecture i386 && \
    apt-get update -q && \
    apt-get install -qy --no-install-recommends libstdc++6:i386 libgcc1:i386 zlib1g:i386 libncurses5:i386 unzip


## Install SDK
ENV ANDROID_HOME /usr/local/android-sdk-linux
RUN cd /usr/local && \
    wget $ANDROID_SDK_URL && \
    unzip $ANDROID_SDK_FILE -d android-sdk-linux && \
    export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools && \
    chgrp -R users $ANDROID_HOME && \
    chmod -R 0775 $ANDROID_HOME && \
    rm $ANDROID_SDK_FILE

# Install android tools and system-image.
ENV PATH $PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/23.0.1
RUN (while true ; do sleep 5; echo y; done) | android update sdk --no-ui --force --all --filter platform-tools,android-27,build-tools-27.0.3,extra-android-support,extra-android-m2repository,sys-img-x86_64-android-27,extra-google-m2repository


# Install node modules
RUN npm config set registry https://registry.npm.taobao.org --global
RUN npm config set disturl https://npm.taobao.org/dist --global
## Install yarn
RUN npm install -g yarn
RUN yarn config set registry https://registry.npm.taobao.org --global
RUN yarn config set disturl https://npm.taobao.org/dist --global

## Install react native
RUN npm install -g react-native-cli

## Clean up when done
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    npm cache verify


# Install watchman
RUN git clone https://github.com/facebook/watchman.git
RUN cd watchman && git checkout v4.9.0 && ./autogen.sh && ./configure && make && make install
RUN rm -rf watchman

# Default react-native web server port
EXPOSE 8081


# User creation
ENV USERNAME dev

RUN adduser --disabled-password --gecos '' $USERNAME


# Add Tini
ENV TINI_VERSION v0.17.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

USER $USERNAME

# Set workdir
# You'll need to run this image with a volume mapped to /home/dev (i.e. -v $(pwd):/home/dev) or override this value
WORKDIR /home/$USERNAME/app

# Tell gradle to store dependencies in a sub directory of the android project
# this persists the dependencies between builds
ENV GRADLE_USER_HOME /home/$USERNAME/app/android/gradle_deps

ENTRYPOINT ["/tini", "--"]
