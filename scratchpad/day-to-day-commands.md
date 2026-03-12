# Day to Day Commands

```bash
ibtisam@dev-machine:~ $ sudo -i
root@dev-machine:~ # docker completion bash > /etc/bash_completion.d/docker
root@dev-machine:~ # exit
logout

ibtisam@dev-machine:~ $ sudo usermod -aG docker $USER
ibtisam@dev-machine:~ $ docker ps
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
ibtisam@dev-machine:~ $ sudo docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
ibtisam@dev-machine:~ $ newgrp docker
ibtisam@dev-machine:~ $ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

```bash
docker buildx build -t abc --platform linux/amd64,linux/arm64 --build-arg USER=ibtisam .
WARNING: No output specified with docker-container driver. Build result will only remain in the build cache. To push result image into registry use --push or to load image into docker use --load
```
