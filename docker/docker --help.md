```bash
docker Container commands

  attach      Attach local standard input, output, and error streams to a running container
  commit      Create a new image from a container's changes
  cp          Copy files/folders between a container and the local filesystem
  create      Create a new container
  diff        Inspect changes to files or directories on a container's filesystem
  exec        Execute a command in a running container
  export      Export a container's filesystem as a tar archive
  inspect     Display detailed information on one or more containers
  kill        Kill one or more running containers
  logs        Fetch the logs of a container
  ls          List containers
  pause       Pause all processes within one or more containers
  port        List port mappings or a specific mapping for the container
  prune       Remove all stopped containers
  rename      Rename a container
  restart     Restart one or more containers
  rm          Remove one or more containers
  run         Create and run a new container from an image
  start       Start one or more stopped containers
  stats       Display a live stream of container(s) resource usage statistics
  stop        Stop one or more running containers
  top         Display the running processes of a container
  unpause     Unpause all processes within one or more containers
  update      Update configuration of one or more containers
  wait        Block until one or more containers stop, then print their exit codes

docker Image commands

  build       Build an image from a Dockerfile
  history     Show the history of an image
  import      Import the contents from a tarball to create a filesystem image
  inspect     Display detailed information on one or more images
  load        Load an image from a tar archive or STDIN
  ls          List images
  prune       Remove unused images
  pull        Download an image from a registry
  push        Upload an image to a registry
  rm          Remove one or more images
  save        Save one or more images to a tar archive (streamed to STDOUT by default)
  tag         Create a tag TARGET_IMAGE that refers to SOURCE_IMAGE

docker run & exec

-a, --attach list          Attach to STDIN, STDOUT or STDERR
    --cap-add list         Add Linux capabilities	--cap-add MAC_ADMIN ubuntu sleep 3600
    --cap-drop list        Drop Linux capabilities	--cap-drop KILL ubuntu sleep 3600
-d, --detach               Run container in background and print container ID
-e, --env list             Set environment variables
    --env-file list        Read in a file of environment variables
    --expose list          Expose a port or a range of ports
    --entrypoint string    Overwrite the default ENTRYPOINT of the image
-i, --interactive          Keep STDIN open even if not attached
    --mount mount          Attach a filesystem mount to the container
    --name string          Assign a name to the container
    --network network      Connect a container to a network
-p, --publish list         Publish a container's port(s) to the host
-P, --publish-all          Publish all exposed ports to random ports
    --privileged=true      Give extended privileges to the command
-q, --quiet                Suppress the pull output
    --read-only            Mount the container's root filesystem as read only
    --restart string       Restart policy to apply when a container exits (def "no") --restart always --restart=on-failure:3
    --rm=ture      	   Automatically remove container & its associated anonymous volumes when it exits
-t, --tty                  Allocate a pseudo-TTY
-u, --user string          Username or UID (format: <name|uid>[:<group|gid>])
-v, --volume list          Bind mount a volume
    --volumes-from list    Mount volumes from the specified container(s)
-w, --workdir string       Working directory inside the container

docker build

    --build-arg stringArray         Set build-time variables
-f, --file string                   Name of the Dockerfile (default: "PATH/Dockerfile")
    --label stringArray             Set metadata for an image
    --network string                Set the networking mode for the "RUN" instructions during build (default "default")
    --no-cache                      Do not use cache when building the image 	--no-cache=true
-q, --quiet                         Suppress the build output and print image ID on success
-t, --tag stringArray               Name and optionally a tag (format: "name:tag")
--target string                     Set the target build stage to build 	--target=prod

docker commit

-a, --author string    Author (e.g., "Ibtisam <loveyou@ibtisam.com>")
-c, --change list      Apply Dockerfile instruction to the created image
-m, --message string   Commit message
-p, --pause            Pause container during commit (default true)

ps & images

-a, --all	      Show all containers/images (default shows just running)
-a, --all             Show all images (default hides intermediate images)
-f, --filter filter   Filter output based on conditions provided “dangling=true”	“status=exited”
    --format string   Format output using a custom template: 'table' 'table TEMPLATE' 'json' 'TEMPLATE'
-n, --last int        Show n last created containers (includes all states) (default -1)
-l, --latest          Show the latest created container (includes all states)
    --no-trunc        Don't truncate output of container/image
-q, --quiet           Only display container/image IDs
-s, --size            Display total file sizes

pull/push

-a, --all-tags         Download all tagged images in the repository
-q, --quiet            Suppress verbose output

login/logout

-p, --password string   Password
    --password-stdin    Take the password from stdin
-u, --username string   Username

List: 		--volumes-from <> --volumes-from <> busybox OR --volumes-from cont1,cont2 busybox
String: 	refers to a single value, docker run -it --name <> -w /app node:alpine /bin/sh 
stringArray:	docker build --build-arg <ARG_NAME>=<value> --build-arg <ARG_NAME2>=<value2> .
```
