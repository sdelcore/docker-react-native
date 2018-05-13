# Docker image for react native.

FROM node:8.11.1

MAINTAINER Spencer <https://github.com/sdelcore>

# Setup environment variables
ENV PATH $PATH:node_modules/.bin

RUN apt-get update -qy && \
    echo deb http://http.debian.net/debian jessie-backports main >> /etc/apt/sources.list && \
    apt-get update -qy && \
    apt-get install -yt jessie-backports openjdk-8-jdk openjdk-8-jre openjdk-8-jdk-headless ca-certificates-java openjdk-8-jre-headless && \
    update-alternatives --config java
## Install 32bit support for Android SDK
RUN dpkg --add-architecture i386 && \
    apt-get update -qy && \
    apt-get install -qy --no-install-recommends python-dev && \
    apt-get install -qy libncurses5:i386 libc6:i386 \
    	libstdc++6:i386 lib32gcc1 lib32ncurses5 \
    	lib32z1 zlib1g:i386 unzip

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
RUN cd watchman && \
    git checkout v4.9.0 && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install
RUN rm -rf watchman

# Default react-native web server port
EXPOSE 8081

# User creation
ENV USERNAME dev
RUN echo "root:root" | chpasswd
#RUN echo "node:node" | chpasswd
RUN adduser --disabled-password --gecos '' $USERNAME
RUN adduser $USERNAME plugdev
#RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Add Tini
ENV TINI_VERSION v0.17.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

RUN chmod -R 755 /opt
RUN chown -R $USERNAME:$USERNAME /opt
RUN chown -R $USERNAME:$USERNAME /home/$USERNAME

USER $USERNAME

# Install Android SDK
## Set correct environment variables.
ENV ANDROID_SDK_FILE sdk-tools-linux-3859397.zip
ENV ANDROID_SDK_URL https://dl.google.com/android/repository/$ANDROID_SDK_FILE

## Install SDK
ENV ANDROID_HOME /opt/android-sdk-linux
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV _JAVA_OPTIONS -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap
RUN cd /opt && \
    wget $ANDROID_SDK_URL && \
    unzip $ANDROID_SDK_FILE -d android-sdk-linux && \
    export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH:$ANDROID_HOME/tools/bin && \
    rm $ANDROID_SDK_FILE

ADD license_accepter.sh /opt
RUN /opt/license_accepter.sh $ANDROID_HOME

# Install android tools and system-image.
ENV PATH $PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/23.0.1
RUN mkdir ~/.android && touch ~/.android/repositories.cfg
RUN $ANDROID_HOME/tools/bin/sdkmanager --update
RUN $ANDROID_HOME/tools/bin/sdkmanager "tools" "platform-tools" \
        "build-tools;26.0.2" "build-tools;25.0.3" \
        "platforms;android-26" "platforms;android-25" \
        "platforms;android-24" "platforms;android-23" \
        "extras;android;m2repository" "extras;google;m2repository"
RUN touch /home/$USERNAME/.android/repositories.cfg

# Set workdir
# You'll need to run this image with a volume mapped to /home/dev (i.e. -v $(pwd):/home/dev) or override this value
WORKDIR /home/$USERNAME/app

# Tell gradle to store dependencies in a sub directory of the android project
# this persists the dependencies between builds
ENV GRADLE_USER_HOME /home/$USERNAME/app/android/gradle_deps

ENTRYPOINT ["/tini", "--"]
