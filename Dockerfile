# Docker image for react native.

FROM node:8.11.1

MAINTAINER Spencer <https://github.com/sdelcore>

# Setup environment variables
ENV USERNAME node
ENV PATH $PATH:node_modules/.bin
ENV PROG /opt

ENV ANDROID_SDK_FILE sdk-tools-linux-3859397.zip
ENV ANDROID_SDK_URL https://dl.google.com/android/repository/$ANDROID_SDK_FILE
ENV ANDROID_HOME $PROG/android-sdk-linux

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV _JAVA_OPTIONS -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap

RUN apt-get update -qy && \
    echo deb http://http.debian.net/debian jessie-backports main >> /etc/apt/sources.list && \
    apt-get update -qy && \
    apt-get install -yt jessie-backports openjdk-8-jdk openjdk-8-jre openjdk-8-jdk-headless ca-certificates-java openjdk-8-jre-headless && \
    update-alternatives --config java
## Install 32bit support for Android SDK
RUN dpkg --add-architecture i386 && \
    apt-get update -qy && \
    apt-get install -qy --no-install-recommends sudo python-dev && \
    apt-get install -qy libncurses5:i386 libc6:i386 \
    	libstdc++6:i386 lib32gcc1 lib32ncurses5 \
    	lib32z1 zlib1g:i386 unzip usbutils tmux nano lsof

# Install node modules
## Install yarn
RUN npm install -g yarn
RUN yarn global add npm react-native-cli react-devtools

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

RUN echo "root:root" | chpasswd
RUN adduser $USERNAME plugdev
RUN echo "$USERNAME ALL=NOPASSWD: ALL" >> /etc/sudoers

RUN mkdir /root/.android && touch /root/.android/repositories.cfg
RUN mkdir /home/$USERNAME/.android
RUN chmod -R 755 $PROG
RUN chown -R $USERNAME:$USERNAME $PROG
RUN chown -R $USERNAME:$USERNAME /home/$USERNAME

USER $USERNAME

# Install Android SDK
## Install SDK
RUN mkdir "$ANDROID_HOME" \
    && cd "$ANDROID_HOME" \
    && curl -o sdk.zip $ANDROID_SDK_URL \
    && unzip sdk.zip \
    && rm sdk.zip \
    && yes | $ANDROID_HOME/tools/bin/sdkmanager --licenses \
    && export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH:$ANDROID_HOME/tools/bin
	
# Install android tools and system-image.
RUN $ANDROID_HOME/tools/bin/sdkmanager --update
RUN $ANDROID_HOME/tools/bin/sdkmanager "tools" "platform-tools" \
        "build-tools;26.0.2" "build-tools;25.0.3" \
		"platforms;android-28" "platforms;android-27" \
        "platforms;android-26" "platforms;android-25" \
        "platforms;android-24" "platforms;android-23" \
        "extras;android;m2repository" "extras;google;m2repository"

RUN touch /home/$USERNAME/.android/repositories.cfg

# Set workdir
# You'll need to run this image with a volume mapped to /home/dev (i.e. -v $(pwd):/home/dev) or override this value
WORKDIR /home/$USERNAME/app

# Tell gradle to store dependencies in a sub directory of the android project
ENV GRADLE_USER_HOME /home/$USERNAME/app/android/gradle_deps
ENV PATH $PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH:$ANDROID_HOME/tools/bin
