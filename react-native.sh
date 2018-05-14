#!/usr/bin/env sh
docker run \
       --rm \
       -it \
       --privileged \
       --user node \
       -v /dev/bus/usb:/dev/bus/usb:z \
       -v $(pwd):/home/node/app:z \
       react-native \
       react-native "$@"
