## Question

1. Build the image `devmaq:3.0` from the Dockerfile at `~/home/Dockerfile`, and
2. Export it in **OCI** format to `~/human-stork/devmac-3.0.tar`.

---

```bash
# 1) Build using podman (same Dockerfile)
podman build -t devmaq:3.0 -f ~/home/Dockerfile ~/home

# 2) Make output dir
mkdir -p ~/human-stork

# 3) Save as OCI archive (podman supports oci-archive)
podman save --format oci-archive -o ~/human-stork/devmac-3.0.tar devmaq:3.0

# 4) (Optional verification)
skopeo inspect oci-archive:~/human-stork/devmac-3.0.tar
# or using podman:
podman image inspect devmaq:3.0
```

## Quick checklist / warnings

* **Do not** push the image to any registry (you said don’t push). The commands above only touch local storage.
* Don’t run the image (no `docker run` / `podman run`).
* Ensure `podman` is installed if you need OCI output; plain `docker save` produces Docker-archive format, not OCI.
* If paths differ, replace `~/home/Dockerfile` and `~/human-stork/devmac-3.0.tar` with your actual locations.
* If you get permission errors with docker/podman, you may need `sudo` or to run as a user in the docker group (depending on your system).
