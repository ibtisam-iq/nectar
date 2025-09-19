Create a secret named `mysql-root-pass` wih key/value pairs as below:

```bash
name: password
value: R00t
```
```bash
thor@jumphost ~$ cat > abc.env
name: password
value: R00t
thor@jumphost ~$ k create secret generic mysql-root-pass --from-env-file abc.env 
error: "name: password" is not a valid key name: a valid environment variable name must consist of alphabetic characters, digits, '_', '-', or '.', and must not start with a digit (e.g. 'my.env-name',  or 'MY_ENV.NAME',  or 'MyEnvName1', regex used for validation is '[-._a-zA-Z][-._a-zA-Z0-9]*')
thor@jumphost ~$
```

Ahh 👍 I see what happened.

The problem is that you wrote the `abc.env` file in **YAML style** (`name:` / `value:`), but `--from-env-file` expects a **simple `KEY=VALUE` format**.

For example, your file should look like this:

```bash
cat > abc.env <<EOF
password=R00t
EOF
```

Then create the secret:

```bash
kubectl create secret generic mysql-root-pass --from-env-file=abc.env
```

✅ This will create a secret named `mysql-root-pass` with:

* Key = `password`
* Value = `R00t`

---

Would you like me to also show you the command to **decode and check** the secret value after creation?
