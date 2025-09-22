Team **Sunny** needs to identify some of their Pods in namespace `sun`. They ask you to **add a new label** `protected: true` to all Pods with an 
existing `label type: worker` or `type: runner`. Also **add an annotation** `protected: do not delete this pod` to all Pods having the new label `protected: true.`

```bash
k -n sun label pod -l type=runner protected=true     # run for label runner
k -n sun label pod -l type=worker protected=true     # run for label worker
k -n sun annotate pod -l protected=true protected="do not delete this pod"
```
