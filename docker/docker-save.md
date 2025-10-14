# `docker save` — In-Depth Guide & Reference

## What is `docker save`

- `docker save` (alias: `docker image save`) exports one or more Docker **images** into a tar archive. It preserves **all layers, metadata, tags, and history**.
- By default, its output is streamed to STDOUT. You can redirect it or use `-o / --output <file>` to save into a file directly.
- It is *not* for containers. That is, it doesn’t capture running container state changes (for that you use `docker export`).

---

## Syntax & Common Usage

| Use Case | Command |
|---|---|
| Save an image into a `.tar` file | `docker save -o image.tar myrepo/myimage:tag` |
| Save an image (via STDOUT) and redirect | `docker save myrepo/myimage:tag > image.tar` |
| Save & compress (gzip) in one step | `docker save myrepo/myimage:tag \| gzip > image.tar.gz` |
| Save multiple images to one archive | `docker save -o images.tar image1:tag image2:tag` |
| Save a specific platform variant (multi-arch) | `docker save --platform linux/arm64 -o image_arm64.tar myrepo/myimage:tag` |

### Flags / Options

- `-o, --output <file>` — write output to given file instead of STDOUT.
- `--platform <os[/arch[/variant]]>` — save only a particular platform’s variant of the image. If the specified variant is not present, the command fails.

---

## Loading What You Saved: `docker load`

To restore an image from a tar (or compressed tar):

```bash
# Load from file
docker load -i image.tar

# Or via STDIN
cat image.tar | docker load

# If compressed (gzip)
gunzip -c image.tar.gz | docker load
````

Newer Docker versions support loading compressed archives (gzip, bzip2, xz, zstd) directly. 
You can also specify `--platform` in `docker load` for multi-arch images (API v1.48+).

---

## What Is Preserved vs What Is Lost

**What is preserved by `docker save` / `docker load`:**

* Full **layer structure** and content
* **Build history** (which commands produced which layer)
* **Metadata**: `ENTRYPOINT`, `CMD`, `ENV`, `LABELS`
* **Tags / repository mapping** (if included in manifest)
* Multi-architecture variants (if the image had them)

**What is *not* lost:**

* Since this is meant to faithfully reproduce the image, nothing crucial (in terms of image runtime) is lost.

**What *docker save* does *not* capture:**

* Any changes made in a running container (unless those changes were committed into an image via `docker commit`)
* State in external volumes
* Dynamically runtime data

---

## Examples & Scenarios

### Basic Save & Load

```bash
docker save -o myapp_v1.tar myuser/app:latest
```

Transfer the `myapp_v1.tar` to another machine, then:

```bash
docker load -i myapp_v1.tar
```

### Save + Compression

```bash
docker save myuser/app:latest | gzip > myapp_v1.tar.gz
```

On the target:

```bash
gunzip -c myapp_v1.tar.gz | docker load
```

### Save Multiple Images at Once

```bash
docker save -o many_images.tar ubuntu:latest nginx:stable
```

Then load:

```bash
docker load -i many_images.tar
```

### Save a Specific Architecture Variant

If your image supports multiple architectures:

```bash
docker save --platform linux/arm64 -o app_arm64.tar myuser/app:latest
```

---

## Pitfalls & Tips

* Attempting `docker load -i image.tar.gz` *without* decompressing may fail on older Docker versions. Better to use `gunzip -c | docker load`.
* Be careful with `--platform`: choosing a variant not present locally causes an error.
* Large images create large tar files — using compression helps reduce size and transfer time.
* If you save by image **ID** instead of name:tag, when loading you might get `<none>` as tag — always use a name:tag to preserve tag.
* You can pipeline across SSH to transfer image directly:

  ```bash
  docker save myimage | gzip | ssh user@remote 'gunzip -c | docker load'
  ```

  This avoids creating a local tar file.
* When saving many images, use a list of image names rather than `docker images -q` directly, to preserve tags.

---
