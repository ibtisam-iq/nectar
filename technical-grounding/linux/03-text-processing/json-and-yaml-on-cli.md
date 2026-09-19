# JSON and YAML on the CLI

Cloud CLIs, Kubernetes and most APIs return JSON, and most DevOps configuration is YAML. `jq` and `yq` query and edit that structure directly, which is more reliable than `grep` and `awk` on text that can change layout.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| `jq .` | Pretty-prints and validates JSON | `jq . file.json` |
| Raw strings | `-r` drops the quotes, for use in shell variables | `jq -r .name` |
| Iterate arrays | `.items[]` emits each element | `jq '.items[]'` |
| Filter | `select(.state == "running")` | `jq 'select(...)'` |
| Build output | `{id: .Id}`, `[...]`, `@tsv`, `@csv` | `jq -c '{id: .Id}'` |
| Shell values | `--arg name value` (string), `--argjson` (JSON) | `jq --arg s x` |
| Missing keys | Return `null`, not an error | `jq '.nope'` |
| Fail on null or false | `-e` sets exit status 1 | `jq -e .key` |
| `yq` (mikefarah) | jq-like syntax for YAML, JSON, XML; `-i` edits in place | `yq --version` |
| Two different yq tools | Go `mikefarah/yq` (EPEL, GitHub releases) and Python `kislyuk/yq` (Ubuntu `apt install yq`) | `apt-cache show yq` |
| Convert formats | `yq -o=json`, `yq -p json -o yaml` | `yq -o=json file.yaml` |
<!-- --8<-- [end:facts] -->

---

## Installing

=== "RHEL / Rocky"

    ```bash
    sudo dnf install jq
    sudo dnf install epel-release && sudo dnf install yq
    ```

    EPEL ships the Go `yq`:

    ```bash
    dnf -q repoquery --qf '%{name} %{version} %{repoid}\n' yq
    ```

    Output:

    ```text
    yq 4.53.3 epel
    ```

=== "Ubuntu / Debian"

    ```bash
    sudo apt install jq
    ```

    The `yq` package in the Ubuntu archive is a different program:

    ```bash
    apt-cache show yq | grep -m2 -E '^(Description|Homepage)'
    ```

    Output:

    ```text
    Homepage: https://github.com/kislyuk/yq
    Description: Command-line YAML processor - jq wrapper for YAML documents
    ```

    Its syntax differs from the Go `yq` used in most documentation; install the Go binary from its GitHub releases or with `snap install yq`.

---

## Querying JSON

The examples ran with jq 1.8.2 and mikefarah yq 4.44.3. The sample file has the shape of `aws ec2 describe-instances` output: reservations containing instances, each with an ID, type, state, private IP and tags.

```bash
jq '.Reservations | length' instances.json
jq '.Reservations[0].Instances[0].InstanceId' instances.json
jq -r '.Reservations[0].Instances[0].InstanceId' instances.json
jq -r '.Reservations[].Instances[] | .InstanceId' instances.json
```

Output:

```text
2
"i-0a1b2c3d4e5f60001"
i-0a1b2c3d4e5f60001
i-0a1b2c3d4e5f60001
i-0a1b2c3d4e5f60002
i-0a1b2c3d4e5f60003
```

!!! note "An array filter emits one result per element"
    `.[]` unwraps an array into separate results, and `|` passes each result to the next filter.

```bash
jq -r '.Reservations[].Instances[] | select(.State.Name == "running") | [.InstanceId, .PrivateIpAddress] | @tsv' instances.json
jq -r '.Reservations[].Instances[] | (.Tags | from_entries | .Name) + " " + .State.Name' instances.json
jq -r '.Reservations[].Instances[] | select(.Tags[] | .Key == "env" and .Value == "prod") | .InstanceId' instances.json
jq --arg state stopped -r '.Reservations[].Instances[] | select(.State.Name == $state) | .InstanceId' instances.json
```

Output:

```text
i-0a1b2c3d4e5f60001	10.0.1.15
i-0a1b2c3d4e5f60003	10.0.2.20
web-01 running
web-02 stopped
db-01 running
i-0a1b2c3d4e5f60001
i-0a1b2c3d4e5f60003
i-0a1b2c3d4e5f60002
```

`from_entries` turns AWS-style `[{"Key": ..., "Value": ...}]` tag lists into an object, so `.Name` works. `jq` never edits files in place: write to a temporary file and `mv` it over the original.

---

## Reshaping and Aggregating

```bash
jq -c '[.Reservations[].Instances[] | {id: .InstanceId, type: .InstanceType}]' instances.json
jq '[.Reservations[].Instances[]] | group_by(.State.Name) | map({state: .[0].State.Name, count: length})' instances.json
jq '.Reservations[0].Instances[0].InstanceType = "t3.large"' instances.json | jq -r '.Reservations[0].Instances[0].InstanceType'
```

Output:

```text
[{"id":"i-0a1b2c3d4e5f60001","type":"t3.medium"},{"id":"i-0a1b2c3d4e5f60002","type":"t3.small"},{"id":"i-0a1b2c3d4e5f60003","type":"m5.large"}]
[
  {
    "state": "running",
    "count": 2
  },
  {
    "state": "stopped",
    "count": 1
  }
]
t3.large
```

---

## Validation and Exit Status

```bash
echo '{"a":1}' | jq '.b.c'
echo '{"a":1' | jq .
echo "rc=$?"
jq -e '.missing' instances.json > /dev/null; echo "rc=$?"
```

Output:

```text
null
jq: parse error: Unfinished JSON term at EOF at line 2, column 0
rc=5
rc=1
```

!!! warning "A null in a script is not an error by default"
    `id=$(jq -r .InstanceId file)` sets `id` to the text `null` when the key is missing, and the script continues. Use `jq -e` (exit 1 on `null` or `false`), or `// empty` to produce nothing.

---

## YAML with yq

```bash
yq '.spec.replicas' deploy.yaml
yq '.spec.template.spec.containers[].image' deploy.yaml
yq '.spec.template.spec.containers[] | select(.name == "web") | .ports[0].containerPort' deploy.yaml
yq -i '.spec.replicas = 3' deploy.yaml
yq '.spec.replicas' deploy.yaml
yq -o=json '.metadata' deploy.yaml
yq -p json -o yaml '.Reservations[0].Instances[0].State' instances.json
```

Output:

```text
2
nginx:1.27
busybox:1.36
80
3
{
  "name": "web",
  "labels": {
    "app": "web"
  }
}
Name: running
```

`yq -i` rewrites the file and keeps comments and key order in most cases; it fits CI jobs that adjust an image tag or a replica count. Built-in queries avoid a second tool: `kubectl -o jsonpath='{.items[*].metadata.name}'`, `aws --query 'Reservations[].Instances[].InstanceId' --output text`.

---

## Common Errors

```bash
printf 'a:\n  b: 1\n c: 2\n' | yq '.'
echo "rc=$?"
```

Output:

```text
Error: bad file '-': yaml: line 2: did not find expected key
rc=1
```

### `jq: parse error: Unfinished JSON term at EOF at line 2, column 0`

**Cause:** the input is not valid JSON: truncated output, an HTML error page, or log text mixed into the stream.

**Fix:** check the raw input (`head -c 200`); with `curl`, use `-f` so HTTP errors do not reach `jq`.

### `Error: bad file '-': yaml: line 2: did not find expected key`

**Cause:** inconsistent indentation; line 3 is indented by one space and belongs to no key.

**Fix:** align the keys; `yamllint` reports the exact position.

### `jq: error (at instances.json:33): Cannot iterate over null (null)`

**Cause:** `.[]` was applied to a missing key.

**Fix:** check the path with `jq 'keys'`, or use `.items[]?`, which skips a missing array silently and exits 0.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: Why use jq instead of grep on JSON output?"
    **Say first:** JSON can change whitespace, key order and line breaks without changing meaning; `jq` parses the structure, so the query keeps working.

    **Proof:** `kubectl get pod web -o json | jq -r .status.phase`

    **Follow-up:** What does `-r` change?
<!-- --8<-- [end:l1] -->

??? question "L2: List the IDs and private IPs of running EC2 instances as tab-separated text."
    **Say first:** iterate, filter on state, output with `@tsv`.

    **Proof:** `jq -r '.Reservations[].Instances[] | select(.State.Name == "running") | [.InstanceId, .PrivateIpAddress] | @tsv'`

    **Follow-up:** How would you do it with `aws --query` alone?

??? question "L2: Print the names of pods that are not Running."
    **Say first:** filter on `.status.phase`.

    **Proof:** `kubectl get pods -o json | jq -r '.items[] | select(.status.phase != "Running") | .metadata.name'`

    **Follow-up:** Why can a pod in `Running` phase still be unhealthy?

??? question "L2: Change the image tag in a Kubernetes manifest from a CI job."
    **Say first:** edit the YAML structurally with `yq -i`.

    **Proof:** `yq -i '.spec.template.spec.containers[0].image = "app:1.4.2"' deploy.yaml`

    **Follow-up:** Which tool is more common for this in a GitOps repository? (`kustomize edit set image`.)

??? question "L2: Pass a shell variable safely into a jq filter."
    **Say first:** `--arg`, never string concatenation.

    **Proof:** `jq --arg env "$ENV" '.items[] | select(.labels.env == $env)'`

    **Follow-up:** When do you need `--argjson` instead?

??? question "L3: A deployment script proceeds with an instance ID of null."
    **Say first:** `jq -r` printed the text `null` for a missing key and the script did not check it.

    **Proof:** the API response changed shape; `jq -e` would exit 1, or `[ "$id" = null ]` can guard it.

    **Follow-up:** How do you make `set -e` catch it?

??? question "L3: A yq command from the documentation fails on an Ubuntu server with a syntax error."
    **Say first:** check which `yq` is installed.

    **Proof:** `yq --version` shows the Python `kislyuk/yq` from `apt`, while the documentation uses Go `mikefarah/yq`.

    **Follow-up:** How do you pin the right one in a CI image?

---

## Related

- [grep and Regex](grep-and-regex.md): text search when the data is not structured
- [awk](awk.md): field processing for plain text
- [xargs and tee](xargs-and-tee.md): acting on the IDs `jq` extracts

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
