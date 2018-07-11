# Usage
## Get image
To clear all containers and images:
```
docker rmi $(docker ps -a -q)
docker rmi $(docker images -q)
```

```
> git clone https://github.com/sdelcore/docker-react-native
> cd docker-react-native
> docker build -t react-native .
```

Next you will need to have the two scripts available in your path. For example you can edit your `.bashrc` and add:
```
export PATH="$HOME/docker-react-native:$PATH"
```

## Create a new react native project
```
> react-native.sh init MyAwesomeProjet
> cd MyAwesomeProjet
> react-native-container.sh
dev> cd node_modules/react-native/
dev> yarn
```

## Run project
Inside container:
```
dev> adb reverse tcp:8081 tcp:8081
dev> react-native start > react-start.log 2>&1 &
dev> react-native run-android
```
### Hot reload
```
dev> watchman watch .
```

To enable it on your phone,
shake it, and select `Enable Hot Reloading`.
You will also need to access `Dev Settings > Debug server host & port for device`
and enter `localhost:8081`.

# Install udev rules
On your host system, you'll need to install the android udev rules if you want to connect your phone or tablet via USB and deploy the react native app directly:
```
wget -S -O - https://raw.githubusercontent.com/M0Rf30/android-udev-rules/master/51-android.rules | sed "s/<username>/$USER/" | sudo tee >/dev/null /etc/udev/rules.d/51-android.rules
sudo udevadm control --reload-rules
```

# Increase max watches
```
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
```
