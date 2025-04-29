# 🔍 Meaning of `-c` in Shell (`sh -c`)

When you run:

```bash
sh -c "echo Hello && date"
```

You're telling the shell:

> “**Execute the following string as a command script**.”

The `-c` flag **switches the shell into "command mode"**, where it takes the **next string** (the following argument) and interprets it as a shell script.

---

## 🧠 So in:

```yaml
command: ["sh", "-c"]
args: ["echo Hello && date"]
```

This becomes:

```bash
sh -c "echo Hello && date"
```

And `sh` sees `"echo Hello && date"` as **a full command to run**, not as separate arguments.

---

## 🧪 Real-World Analogy

Imagine `sh` as a script interpreter:

- Without `-c`, it expects a script file like `sh myscript.sh`.
- With `-c`, it expects a **script as a string**, like `sh -c "do this"`.

---

## 🧠 Important Detail

If you *omit* `-c`, and just pass a string like:

```bash
sh "echo Hello && date"
```

It will try to **open a file named `echo Hello && date`**, which obviously fails.
