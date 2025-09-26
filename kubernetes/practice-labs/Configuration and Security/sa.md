Team **Neptune** has its own ServiceAccount named `neptune-sa-v2` in Namespace `neptune`. 
A coworker needs the **token from the Secret** that belongs to that ServiceAccount. Write the **base64 decoded** token to file `/opt/course/5/token on ckad7326`.

✅ To pass **this specific question**, you need to:

1. Find the Secret for the SA:

   ```bash
   kubectl -n neptune get secret
   ```
2. Decode the token and write it:

   ```bash
   kubectl -n neptune get secret <secret-name> -o jsonpath='{.data.token}' | base64 -d > /opt/course/5/token
   ```

---

👉 In a **real CKA/CKAD exam on 1.29+**, you’d be right with `kubectl create token`.
👉 In **practice platforms**, follow exactly the task wording, even if it’s outdated — otherwise the grader marks it wrong.

---

Would you like me to show you a **universal one-liner** that first checks if a Secret exists and falls back to `kubectl create token` if not? That way you’d cover **both real cluster and exam simulator** cases.
