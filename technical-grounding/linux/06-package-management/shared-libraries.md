# Shared Libraries

Most Linux programs are dynamically linked: at start-up the loader (`ld.so`) finds each shared library the binary names and maps it into memory. When that search fails, the program never runs, which makes the search order the first thing to know for `error while loading shared libraries`.

**Track:** Advanced · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Loader | `/lib64/ld-linux-x86-64.so.2`, named in the ELF header | `file <binary>` |
| Needed libraries | `NEEDED` entries in the dynamic section | `readelf -d <binary>` |
| Resolved paths | `ldd` shows where each library is found | `ldd <binary>` |
| Search order | `LD_LIBRARY_PATH`, the binary's `RUNPATH`, `/etc/ld.so.cache`, then the default directories; a legacy `RPATH` is searched before `LD_LIBRARY_PATH` | `LD_DEBUG=libs <binary>` |
| Cache | `ldconfig` builds `/etc/ld.so.cache` from `/etc/ld.so.conf.d/*.conf` | `ldconfig -p` |
| soname | Name a library promises to stay compatible under (`libgreet.so.1`) | `readelf -d lib.so` |
| Symlinks | `libx.so.1.0` real file; `libx.so.1` for programs (soname); `libx.so` for the compiler (`-dev` or `-devel` packages) | `ls -l` |
| `RUNPATH` | Directories stored in the binary; `$ORIGIN` means the binary's own directory | `patchelf --set-rpath` |
| `LD_PRELOAD` | Loads a library first, overriding symbols; ignored for SUID programs | `LD_PRELOAD=... cmd` |
| Symbol versions | `GLIBC_2.34` in a binary sets the minimum glibc | `objdump -T <binary>` |
| Static binaries | Contain their libraries; `ldd` prints `not a dynamic executable` | `ldd <binary>` |
<!-- --8<-- [end:facts] -->

---

## Building a Library and a Program

A one-function library, built with a soname and the usual symlinks, and a program linked against it:

```bash
gcc -shared -fPIC -Wl,-soname,libgreet.so.1 -o libgreet.so.1.0 greet.c
ln -sf libgreet.so.1.0 libgreet.so.1
ln -sf libgreet.so.1 libgreet.so
gcc -o app app.c -L. -lgreet
ls -l libgreet*
readelf -d app | grep -E 'NEEDED|RUNPATH|RPATH'
readelf -d libgreet.so.1.0 | grep SONAME
```

Output:

```text
lrwxrwxrwx 1 laborant laborant    13 Sep 16 18:36 libgreet.so -> libgreet.so.1
lrwxrwxrwx 1 laborant laborant    15 Sep 16 18:36 libgreet.so.1 -> libgreet.so.1.0
-rwxrwxr-x 1 laborant laborant 15544 Sep 16 18:36 libgreet.so.1.0
 0x0000000000000001 (NEEDED)             Shared library: [libgreet.so.1]
 0x0000000000000001 (NEEDED)             Shared library: [libc.so.6]
 0x000000000000000e (SONAME)             Library soname: [libgreet.so.1]
```

The linker used `libgreet.so` to build, but recorded the soname `libgreet.so.1`, which is what the loader looks for at run time.

---

## When the Library Is Not Found

```bash
./app; echo "rc=$?"
ldd ./app | grep greet
LD_LIBRARY_PATH=$PWD ./app
```

Output:

```text
./app: error while loading shared libraries: libgreet.so.1: cannot open shared object file: No such file or directory
rc=127
	libgreet.so.1 => not found
hello, world
```

The current directory is not searched. There are three permanent fixes:

| Fix | How | Suits |
|---|---|---|
| Register the directory | File in `/etc/ld.so.conf.d/`, then `ldconfig` | Libraries shared by several programs |
| Store the path in the binary | `RUNPATH` at link time (`-Wl,-rpath,...`) or `patchelf --set-rpath` | Self-contained application bundles |
| Wrapper script | `LD_LIBRARY_PATH=... exec app "$@"` | Vendor software that cannot be rebuilt |

```bash
sudo mkdir -p /opt/greet/lib
sudo cp -a libgreet.so* /opt/greet/lib/
echo /opt/greet/lib | sudo tee /etc/ld.so.conf.d/greet.conf
sudo ldconfig
ldconfig -p | grep greet
./app
ldd ./app | grep greet
```

Output:

```text
/opt/greet/lib
	libgreet.so.1 (libc6,x86-64) => /opt/greet/lib/libgreet.so.1
	libgreet.so (libc6,x86-64) => /opt/greet/lib/libgreet.so
hello, world
	libgreet.so.1 => /opt/greet/lib/libgreet.so.1 (0x00007feee4ef3000)
```

!!! warning "A new library directory needs ldconfig"
    Adding a `.conf` file changes nothing until `ldconfig` rebuilds `/etc/ld.so.cache`. Package managers run it in their scripts; manual installs into `/opt` or `/usr/local/lib` often forget it.

With the configuration removed again, `RUNPATH` and `$ORIGIN` make a relocatable bundle:

```bash
patchelf --set-rpath '$ORIGIN/../lib' app
readelf -d app | grep RUNPATH
mkdir -p ../bundle/bin ../bundle/lib && cp app ../bundle/bin/ && cp -a libgreet.so* ../bundle/lib/
../bundle/bin/app
```

Output:

```text
 0x000000000000001d (RUNPATH)            Library runpath: [$ORIGIN/../lib]
hello, world
```

---

## Watching the Search

```bash
LD_DEBUG=libs ../bundle/bin/app 2>&1 | grep -E 'find library|trying file' | head -4
/lib64/ld-linux-x86-64.so.2 --list ../bundle/bin/app | head -3
cat /etc/ld.so.conf; ls /etc/ld.so.conf.d/
```

Output:

```text
      6738:	find library=libgreet.so.1 [0]; searching
      6738:	  trying file=/home/laborant/bundle/bin/../lib/glibc-hwcaps/x86-64-v4/libgreet.so.1
      6738:	  trying file=/home/laborant/bundle/bin/../lib/glibc-hwcaps/x86-64-v3/libgreet.so.1
      6738:	  trying file=/home/laborant/bundle/bin/../lib/glibc-hwcaps/x86-64-v2/libgreet.so.1
	linux-vdso.so.1 (0x00007ffc3b290000)
	libgreet.so.1 => /home/laborant/libdemo/../bundle/bin/../lib/libgreet.so.1 (0x00007f1889a9d000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f1889800000)
include /etc/ld.so.conf.d/*.conf

libc.conf
x86_64-linux-gnu.conf
```

The loader tries CPU-specific subdirectories (`glibc-hwcaps/x86-64-v4` and lower) inside each search directory before the directory itself.

!!! danger "ldd can run code from the binary"
    `ldd` may execute the program's loader, so running it on an untrusted binary is unsafe. `readelf -d` or `objdump -p` read the same information without executing anything.

---

## Preloading and Symbol Versions

`LD_PRELOAD` loads a library before all others, so its symbols win:

```bash
gcc -shared -fPIC -o libshout.so shout.c
LD_PRELOAD=$PWD/libshout.so ../bundle/bin/app
nm -D --defined-only libgreet.so.1.0 | grep greet
objdump -T ../bundle/bin/app | grep -E 'greet|GLIBC' | head -3
```

Output:

```text
HELLO, world! (preloaded)
0000000000001119 T greet
0000000000000000      DF *UND*	0000000000000000 (GLIBC_2.34) __libc_start_main
0000000000000000      DF *UND*	0000000000000000  Base        greet
0000000000000000  w   DF *UND*	0000000000000000 (GLIBC_2.2.5) __cxa_finalize
```

`LD_PRELOAD` is how memory debuggers and `libfaketime` work, and also a known persistence trick; `/etc/ld.so.preload` applies it system-wide and is worth checking during an incident. The `GLIBC_2.34` reference means this binary needs glibc 2.34 or newer.

---

## Common Errors

### `error while loading shared libraries: libgreet.so.1: cannot open shared object file: No such file or directory`

**Cause:** the library is not installed, or its directory is not in the search path (exit status 127).

**Fix:** `ldd <binary>` to see what is missing; install the package (`dnf provides '*/libgreet.so.1'`, `apt-file search libgreet.so.1`) or register the directory with `ldconfig`.

A binary built on Fedora 44 (glibc 2.43) that calls `pthread_gettid_np()`, added in glibc 2.42, copied to Ubuntu 24.04:

```bash
./app-fedora44; echo "rc=$?"
ldd --version | head -1
objdump -T app-fedora44 | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1
```

Output:

```text
./app-fedora44: /lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.42' not found (required by ./app-fedora44)
rc=1
ldd (Ubuntu GLIBC 2.39-0ubuntu8.9) 2.39
GLIBC_2.42
```

### ``version `GLIBC_2.42' not found (required by ./app-fedora44)``

**Cause:** the binary was built against a newer glibc than the one installed.

**Fix:** build on the oldest supported target, link statically, or run it in a container based on the build distribution.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between static and dynamic linking?"
    **Say first:** static linking copies library code into the binary; dynamic linking records library names that the loader finds and maps at start-up, so libraries are shared and updated separately.

    **Proof:** `ldd /usr/bin/ssh` lists libraries; a static Go binary reports `not a dynamic executable`.

    **Follow-up:** What is the security consequence of each for patching?
<!-- --8<-- [end:l1] -->

??? question "L2: A vendor tool fails with error while loading shared libraries. Find and fix the missing library."
    **Say first:** list the missing names, find the package or directory, then register it.

    **Proof:** `ldd ./tool | grep 'not found'`; install the package, or `echo /opt/vendor/lib | sudo tee /etc/ld.so.conf.d/vendor.conf && sudo ldconfig`.

    **Follow-up:** Why not export `LD_LIBRARY_PATH` in `/etc/profile`?

??? question "L2: Show which glibc version a binary needs."
    **Say first:** read the versioned symbol references.

    **Proof:** `objdump -T ./app | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1`

    **Follow-up:** How do you check the installed glibc? (`ldd --version`.)

??? question "L2: Ship an application with its own libraries in one directory."
    **Say first:** set a relative `RUNPATH` with `$ORIGIN`.

    **Proof:** `patchelf --set-rpath '$ORIGIN/../lib' bin/app`, or link with `-Wl,-rpath,'$ORIGIN/../lib'`.

    **Follow-up:** How does that compare with a container image?

??? question "L3: An application works when started from a shell but fails under systemd with a shared library error."
    **Say first:** compare environments: the shell has `LD_LIBRARY_PATH`, the unit does not.

    **Proof:** `echo $LD_LIBRARY_PATH` in the shell; `/proc/<pid>/environ` of the service lacks it.

    **Follow-up:** What is the better fix than `Environment=LD_LIBRARY_PATH=`?

??? question "L3: During an incident, every command on a server behaves oddly, including ls."
    **Say first:** check for a system-wide preload.

    **Proof:** `cat /etc/ld.so.preload` lists an unknown library; `ldd /usr/bin/ls` shows it loaded first.

    **Follow-up:** Why can a statically linked busybox help here?

??? question "L4: What happens between execve and main for a dynamically linked program?"
    **Say first:** the kernel maps the program and its `PT_INTERP` loader and starts the loader, which reads `NEEDED` entries, searches and maps each library, resolves relocations, runs initializers, then jumps to the program's entry point.

    **Proof:** `LD_DEBUG=libs,reloc ./app` and `strace -e trace=openat,mmap ./app` show the searches and mappings before any program output.

    **Don't say:** "The kernel loads the shared libraries."

---

## Related

- [Architecture](../00-foundations/architecture.md): the C library and the loader
- [Packaging Concepts](packaging-concepts.md): soname dependencies such as `libc.so.6()(64bit)`
- [Command Resolution](../01-shell-and-cli/command-resolution.md): `required file not found` for a missing loader
- [Round 4: Internals](../interview/round-4-internals.md): more "what happens when" questions

Captured on Rocky Linux 10.2, Fedora 44 (where noted) and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
