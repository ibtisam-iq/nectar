```bash
controlplane ~ ➜  ls
LICENSE  README.md

controlplane ~ ➜  openssl genrsa -out ibtisam.key 3072

controlplane ~ ➜  ls
ibtisam.key  LICENSE  README.md

controlplane ~ ➜  rm -rf LICENSE README.md 

controlplane ~ ➜  openssl req -new -key ibtisam.key -out ibtisam.csr -subj "/CN=ibtisam"

controlplane ~ ➜  ls
ibtisam.csr  ibtisam.key

controlplane ~ ➜  vi text.txt

controlplane ~ ➜  cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ibtisam # example
spec:
  request: $(cat ibtisam.csr | base64 | tr -d "\n")
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # one day
  usages:
  - client auth
EOF
certificatesigningrequest.certificates.k8s.io/ibtisam created

controlplane ~ ➜  ls
'\'   ibtisam.csr   ibtisam.key   text.txt

controlplane ~ ➜  vi text.txt

controlplane ~ ➜  cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ibtisam # example
spec:
  request: $(cat ibtisam.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # one day
  usages:
  - client auth
EOF
certificatesigningrequest.certificates.k8s.io/ibtisam unchanged

controlplane ~ ➜  ls
'\'   ibtisam.csr   ibtisam.key   text.txt

controlplane ~ ➜  cat ibtisam.csr | base64 | tr -d "\n"
LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlJRFZ6Q0NBYjhDQVFBd0VqRVFNQTRHQTFVRUF3d0hhV0owYVhOaGJUQ0NBYUl3RFFZSktvWklodmNOQVFFQgpCUUFEZ2dHUEFEQ0NBWW9DZ2dHQkFMZ0Y5MW9sNVUyd24vS1Erd2tZZFM0b1VzTU1rUmlobGczbWdsQTFmbFdwCnJpNnB0U3hZSzQ5Wk5MaVVVUmkweGpuWURrQlBMQWdrK3dIZkZpelBOS0dCaXUvNDFnVVpmVlpiSldsazhiOGsKWG1LcmNQRmJXODgrbVNvcHlNcXJBcjRsM0JPUThlK1I3OENjZTRlRkpPZEFqcHVRODMyakFDT0p3V1RLV1UvbAp2SmRJVEpaMEVMWjFkUnZHam5GUHZSS0Z3V3d0TVlrVlhEYTVFRFl0Sk5zUG5MZ0paamtkM2FBRWlSbXFZcjMxClpaWEdYZUVVTm5kYThyVDlyVU10L2wvTlJKRzJZUGg4SW9KMDNjSFl2Zmt3Z1o4T0RPeEN4YStUSEo2UXZMRzIKcnNpMEcwQVdlbEMwRisxM2xrZE5yRjJFSE9PZVA5MGpTT0EyMHZFVGd6cEltNjcxRGRnYkZoZVU1OTBvUTZTMgppeFdUbHNxdjYwTEZSWGd0QW5VbDR4ajUwUG11eGZ5RW5zQ0duSENYbmxwVy9mc1RtMUZlUm5kenBWNmM4c2xrClI2Tk5ac2tmbG5SZFdDcmRUanNROVhGSWVwYVpzdWN3alE3Y0RiTktkUTFhaUVWdXZQMUJIMHk2ckJqajZCWDEKNE1KMjlZUVhYRDBSWTVuSEs5MVFlUUlEQVFBQm9BQXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnR0JBQ2lSMFNsawpJWnE3ZHJZTUlORTNZOWFyQ0NTRlZmMitMWjRpR2ZwRThmdmluZEZKdlZaaDRxekpaalBvWjEvRFBiamlyVm9PCmxIRjgrdllSTmt4VDFGNFZJRy83RnU3QWx3MnZNa0JWTThBcS9xRVVSVUVrb2M4SWQyQXNQeUNteU1tQXhMblQKVmM4bWl3dWxTdCtDaDQ0STNCa3JSUEtnWmw0Z1pCTlZQTHpqMmJNdmwyL2JjUjg3YnFlTkd6dk0rOU1DS1Z6TgpmNmFPbmVHV3ZjTlYwbHcvbldEZjE0ZFpQOSt2QVVFQmM4Z0JyYUJEZ3ViYWp2VXlwMldWQ05CSGljVitpOHh0CkJTSXlsd0EyY2wxTTM4UHpxQWRHUUlSaHdpRWtYWmdnR1R2SjhhSzVMKzlDbEFMbTk0eGl5RVBFblhYRGxrMkcKUHRPbVI1c2I2eCtxVDI5eXZJS3B1amRNNFdoRVl0VVdQUjBORUZ3ZkdJVit0d0VCV0UrMVZVVVhxcit6VlBuegozSElWMXh2dGY1dTJ3dE1ncXJ5dmMvOURYVWI4VXVLZUNYQ3g1elBlR2FqZm05OURDSGpMN3UwVlMwdEtnTGIyCjVtcGt5MHFXRk45eWZpUExoQXN6OTBLT3h0cmZCeThlQk5BL09wSWFCSzZENkVnT1FnL1VPaWg1QVE9PQotLS0tLUVORCBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0K
controlplane ~ ➜  vi abc.yaml

controlplane ~ ➜  k apply -f abc.yaml 
certificatesigningrequest.certificates.k8s.io/ibtisam unchanged

controlplane ~ ➜  ls
'\'   abc.yaml   ibtisam.csr   ibtisam.key   text.txt

controlplane ~ ➜  k get csr
NAME        AGE     SIGNERNAME                                    REQUESTOR                  REQUESTEDDURATION   CONDITION
csr-n4xjs   44m     kubernetes.io/kube-apiserver-client-kubelet   system:bootstrap:074czq    <none>              Approved,Issued
csr-np9kh   45m     kubernetes.io/kube-apiserver-client-kubelet   system:node:controlplane   <none>              Approved,Issued
csr-rl2zf   45m     kubernetes.io/kube-apiserver-client-kubelet   system:bootstrap:yemp9u    <none>              Approved,Issued
ibtisam     6m40s   kubernetes.io/kube-apiserver-client           kubernetes-admin           24h                 Pending

controlplane ~ ➜  cat abc.yaml 
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ibtisam # example
spec:
  request: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlJRFZ6Q0NBYjhDQVFBd0VqRVFNQTRHQTFVRUF3d0hhV0owYVhOaGJUQ0NBYUl3RFFZSktvWklodmNOQVFFQgpCUUFEZ2dHUEFEQ0NBWW9DZ2dHQkFMZ0Y5MW9sNVUyd24vS1Erd2tZZFM0b1VzTU1rUmlobGczbWdsQTFmbFdwCnJpNnB0U3hZSzQ5Wk5MaVVVUmkweGpuWURrQlBMQWdrK3dIZkZpelBOS0dCaXUvNDFnVVpmVlpiSldsazhiOGsKWG1LcmNQRmJXODgrbVNvcHlNcXJBcjRsM0JPUThlK1I3OENjZTRlRkpPZEFqcHVRODMyakFDT0p3V1RLV1UvbAp2SmRJVEpaMEVMWjFkUnZHam5GUHZSS0Z3V3d0TVlrVlhEYTVFRFl0Sk5zUG5MZ0paamtkM2FBRWlSbXFZcjMxClpaWEdYZUVVTm5kYThyVDlyVU10L2wvTlJKRzJZUGg4SW9KMDNjSFl2Zmt3Z1o4T0RPeEN4YStUSEo2UXZMRzIKcnNpMEcwQVdlbEMwRisxM2xrZE5yRjJFSE9PZVA5MGpTT0EyMHZFVGd6cEltNjcxRGRnYkZoZVU1OTBvUTZTMgppeFdUbHNxdjYwTEZSWGd0QW5VbDR4ajUwUG11eGZ5RW5zQ0duSENYbmxwVy9mc1RtMUZlUm5kenBWNmM4c2xrClI2Tk5ac2tmbG5SZFdDcmRUanNROVhGSWVwYVpzdWN3alE3Y0RiTktkUTFhaUVWdXZQMUJIMHk2ckJqajZCWDEKNE1KMjlZUVhYRDBSWTVuSEs5MVFlUUlEQVFBQm9BQXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnR0JBQ2lSMFNsawpJWnE3ZHJZTUlORTNZOWFyQ0NTRlZmMitMWjRpR2ZwRThmdmluZEZKdlZaaDRxekpaalBvWjEvRFBiamlyVm9PCmxIRjgrdllSTmt4VDFGNFZJRy83RnU3QWx3MnZNa0JWTThBcS9xRVVSVUVrb2M4SWQyQXNQeUNteU1tQXhMblQKVmM4bWl3dWxTdCtDaDQ0STNCa3JSUEtnWmw0Z1pCTlZQTHpqMmJNdmwyL2JjUjg3YnFlTkd6dk0rOU1DS1Z6TgpmNmFPbmVHV3ZjTlYwbHcvbldEZjE0ZFpQOSt2QVVFQmM4Z0JyYUJEZ3ViYWp2VXlwMldWQ05CSGljVitpOHh0CkJTSXlsd0EyY2wxTTM4UHpxQWRHUUlSaHdpRWtYWmdnR1R2SjhhSzVMKzlDbEFMbTk0eGl5RVBFblhYRGxrMkcKUHRPbVI1c2I2eCtxVDI5eXZJS3B1amRNNFdoRVl0VVdQUjBORUZ3ZkdJVit0d0VCV0UrMVZVVVhxcit6VlBuegozSElWMXh2dGY1dTJ3dE1ncXJ5dmMvOURYVWI4VXVLZUNYQ3g1elBlR2FqZm05OURDSGpMN3UwVlMwdEtnTGIyCjVtcGt5MHFXRk45eWZpUExoQXN6OTBLT3h0cmZCeThlQk5BL09wSWFCSzZENkVnT1FnL1VPaWg1QVE9PQotLS0tLUVORCBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0K
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # one day
  usages:
  - client auth

controlplane ~ ➜  k get csr
NAME        AGE     SIGNERNAME                                    REQUESTOR                  REQUESTEDDURATION   CONDITION
csr-n4xjs   45m     kubernetes.io/kube-apiserver-client-kubelet   system:bootstrap:074czq    <none>              Approved,Issued
csr-np9kh   46m     kubernetes.io/kube-apiserver-client-kubelet   system:node:controlplane   <none>              Approved,Issued
csr-rl2zf   45m     kubernetes.io/kube-apiserver-client-kubelet   system:bootstrap:yemp9u    <none>              Approved,Issued
ibtisam     7m14s   kubernetes.io/kube-apiserver-client           kubernetes-admin           24h                 Pending

controlplane ~ ➜  k certificate approve ibtisam
certificatesigningrequest.certificates.k8s.io/ibtisam approved

controlplane ~ ➜  k get csr
NAME        AGE     SIGNERNAME                                    REQUESTOR                  REQUESTEDDURATION   CONDITION
csr-n4xjs   45m     kubernetes.io/kube-apiserver-client-kubelet   system:bootstrap:074czq    <none>              Approved,Issued
csr-np9kh   46m     kubernetes.io/kube-apiserver-client-kubelet   system:node:controlplane   <none>              Approved,Issued
csr-rl2zf   46m     kubernetes.io/kube-apiserver-client-kubelet   system:bootstrap:yemp9u    <none>              Approved,Issued
ibtisam     7m40s   kubernetes.io/kube-apiserver-client           kubernetes-admin           24h                 Approved,Issued

controlplane ~ ➜  kubectl get csr/ibtisam -o yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"certificates.k8s.io/v1","kind":"CertificateSigningRequest","metadata":{"annotations":{},"name":"ibtisam"},"spec":{"expirationSeconds":86400,"request":"LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlJRFZ6Q0NBYjhDQVFBd0VqRVFNQTRHQTFVRUF3d0hhV0owYVhOaGJUQ0NBYUl3RFFZSktvWklodmNOQVFFQgpCUUFEZ2dHUEFEQ0NBWW9DZ2dHQkFMZ0Y5MW9sNVUyd24vS1Erd2tZZFM0b1VzTU1rUmlobGczbWdsQTFmbFdwCnJpNnB0U3hZSzQ5Wk5MaVVVUmkweGpuWURrQlBMQWdrK3dIZkZpelBOS0dCaXUvNDFnVVpmVlpiSldsazhiOGsKWG1LcmNQRmJXODgrbVNvcHlNcXJBcjRsM0JPUThlK1I3OENjZTRlRkpPZEFqcHVRODMyakFDT0p3V1RLV1UvbAp2SmRJVEpaMEVMWjFkUnZHam5GUHZSS0Z3V3d0TVlrVlhEYTVFRFl0Sk5zUG5MZ0paamtkM2FBRWlSbXFZcjMxClpaWEdYZUVVTm5kYThyVDlyVU10L2wvTlJKRzJZUGg4SW9KMDNjSFl2Zmt3Z1o4T0RPeEN4YStUSEo2UXZMRzIKcnNpMEcwQVdlbEMwRisxM2xrZE5yRjJFSE9PZVA5MGpTT0EyMHZFVGd6cEltNjcxRGRnYkZoZVU1OTBvUTZTMgppeFdUbHNxdjYwTEZSWGd0QW5VbDR4ajUwUG11eGZ5RW5zQ0duSENYbmxwVy9mc1RtMUZlUm5kenBWNmM4c2xrClI2Tk5ac2tmbG5SZFdDcmRUanNROVhGSWVwYVpzdWN3alE3Y0RiTktkUTFhaUVWdXZQMUJIMHk2ckJqajZCWDEKNE1KMjlZUVhYRDBSWTVuSEs5MVFlUUlEQVFBQm9BQXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnR0JBQ2lSMFNsawpJWnE3ZHJZTUlORTNZOWFyQ0NTRlZmMitMWjRpR2ZwRThmdmluZEZKdlZaaDRxekpaalBvWjEvRFBiamlyVm9PCmxIRjgrdllSTmt4VDFGNFZJRy83RnU3QWx3MnZNa0JWTThBcS9xRVVSVUVrb2M4SWQyQXNQeUNteU1tQXhMblQKVmM4bWl3dWxTdCtDaDQ0STNCa3JSUEtnWmw0Z1pCTlZQTHpqMmJNdmwyL2JjUjg3YnFlTkd6dk0rOU1DS1Z6TgpmNmFPbmVHV3ZjTlYwbHcvbldEZjE0ZFpQOSt2QVVFQmM4Z0JyYUJEZ3ViYWp2VXlwMldWQ05CSGljVitpOHh0CkJTSXlsd0EyY2wxTTM4UHpxQWRHUUlSaHdpRWtYWmdnR1R2SjhhSzVMKzlDbEFMbTk0eGl5RVBFblhYRGxrMkcKUHRPbVI1c2I2eCtxVDI5eXZJS3B1amRNNFdoRVl0VVdQUjBORUZ3ZkdJVit0d0VCV0UrMVZVVVhxcit6VlBuegozSElWMXh2dGY1dTJ3dE1ncXJ5dmMvOURYVWI4VXVLZUNYQ3g1elBlR2FqZm05OURDSGpMN3UwVlMwdEtnTGIyCjVtcGt5MHFXRk45eWZpUExoQXN6OTBLT3h0cmZCeThlQk5BL09wSWFCSzZENkVnT1FnL1VPaWg1QVE9PQotLS0tLUVORCBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0K","signerName":"kubernetes.io/kube-apiserver-client","usages":["client auth"]}}
  creationTimestamp: "2025-08-08T05:47:11Z"
  name: ibtisam
  resourceVersion: "4979"
  uid: 4ccc1540-82c0-4061-8fb7-c29130997128
spec:
  expirationSeconds: 86400
  extra:
    authentication.kubernetes.io/credential-id:
    - X509SHA256=dc4f9f4fd4206177eb6a9db220e880137c8063b575f6c6476812ad75366f0a54
  groups:
  - kubeadm:cluster-admins
  - system:authenticated
  request: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlJRFZ6Q0NBYjhDQVFBd0VqRVFNQTRHQTFVRUF3d0hhV0owYVhOaGJUQ0NBYUl3RFFZSktvWklodmNOQVFFQgpCUUFEZ2dHUEFEQ0NBWW9DZ2dHQkFMZ0Y5MW9sNVUyd24vS1Erd2tZZFM0b1VzTU1rUmlobGczbWdsQTFmbFdwCnJpNnB0U3hZSzQ5Wk5MaVVVUmkweGpuWURrQlBMQWdrK3dIZkZpelBOS0dCaXUvNDFnVVpmVlpiSldsazhiOGsKWG1LcmNQRmJXODgrbVNvcHlNcXJBcjRsM0JPUThlK1I3OENjZTRlRkpPZEFqcHVRODMyakFDT0p3V1RLV1UvbAp2SmRJVEpaMEVMWjFkUnZHam5GUHZSS0Z3V3d0TVlrVlhEYTVFRFl0Sk5zUG5MZ0paamtkM2FBRWlSbXFZcjMxClpaWEdYZUVVTm5kYThyVDlyVU10L2wvTlJKRzJZUGg4SW9KMDNjSFl2Zmt3Z1o4T0RPeEN4YStUSEo2UXZMRzIKcnNpMEcwQVdlbEMwRisxM2xrZE5yRjJFSE9PZVA5MGpTT0EyMHZFVGd6cEltNjcxRGRnYkZoZVU1OTBvUTZTMgppeFdUbHNxdjYwTEZSWGd0QW5VbDR4ajUwUG11eGZ5RW5zQ0duSENYbmxwVy9mc1RtMUZlUm5kenBWNmM4c2xrClI2Tk5ac2tmbG5SZFdDcmRUanNROVhGSWVwYVpzdWN3alE3Y0RiTktkUTFhaUVWdXZQMUJIMHk2ckJqajZCWDEKNE1KMjlZUVhYRDBSWTVuSEs5MVFlUUlEQVFBQm9BQXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnR0JBQ2lSMFNsawpJWnE3ZHJZTUlORTNZOWFyQ0NTRlZmMitMWjRpR2ZwRThmdmluZEZKdlZaaDRxekpaalBvWjEvRFBiamlyVm9PCmxIRjgrdllSTmt4VDFGNFZJRy83RnU3QWx3MnZNa0JWTThBcS9xRVVSVUVrb2M4SWQyQXNQeUNteU1tQXhMblQKVmM4bWl3dWxTdCtDaDQ0STNCa3JSUEtnWmw0Z1pCTlZQTHpqMmJNdmwyL2JjUjg3YnFlTkd6dk0rOU1DS1Z6TgpmNmFPbmVHV3ZjTlYwbHcvbldEZjE0ZFpQOSt2QVVFQmM4Z0JyYUJEZ3ViYWp2VXlwMldWQ05CSGljVitpOHh0CkJTSXlsd0EyY2wxTTM4UHpxQWRHUUlSaHdpRWtYWmdnR1R2SjhhSzVMKzlDbEFMbTk0eGl5RVBFblhYRGxrMkcKUHRPbVI1c2I2eCtxVDI5eXZJS3B1amRNNFdoRVl0VVdQUjBORUZ3ZkdJVit0d0VCV0UrMVZVVVhxcit6VlBuegozSElWMXh2dGY1dTJ3dE1ncXJ5dmMvOURYVWI4VXVLZUNYQ3g1elBlR2FqZm05OURDSGpMN3UwVlMwdEtnTGIyCjVtcGt5MHFXRk45eWZpUExoQXN6OTBLT3h0cmZCeThlQk5BL09wSWFCSzZENkVnT1FnL1VPaWg1QVE9PQotLS0tLUVORCBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0K
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
  username: kubernetes-admin
status:
  certificate: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURkekNDQWwrZ0F3SUJBZ0lRUHJ3aStNSm1xYlBuSUc1SzhGeTVOekFOQmdrcWhraUc5dzBCQVFzRkFEQVYKTVJNd0VRWURWUVFERXdwcmRXSmxjbTVsZEdWek1CNFhEVEkxTURnd09EQTFORGswTmxvWERUSTFNRGd3T1RBMQpORGswTmxvd0VqRVFNQTRHQTFVRUF4TUhhV0owYVhOaGJUQ0NBYUl3RFFZSktvWklodmNOQVFFQkJRQURnZ0dQCkFEQ0NBWW9DZ2dHQkFMZ0Y5MW9sNVUyd24vS1Erd2tZZFM0b1VzTU1rUmlobGczbWdsQTFmbFdwcmk2cHRTeFkKSzQ5Wk5MaVVVUmkweGpuWURrQlBMQWdrK3dIZkZpelBOS0dCaXUvNDFnVVpmVlpiSldsazhiOGtYbUtyY1BGYgpXODgrbVNvcHlNcXJBcjRsM0JPUThlK1I3OENjZTRlRkpPZEFqcHVRODMyakFDT0p3V1RLV1UvbHZKZElUSlowCkVMWjFkUnZHam5GUHZSS0Z3V3d0TVlrVlhEYTVFRFl0Sk5zUG5MZ0paamtkM2FBRWlSbXFZcjMxWlpYR1hlRVUKTm5kYThyVDlyVU10L2wvTlJKRzJZUGg4SW9KMDNjSFl2Zmt3Z1o4T0RPeEN4YStUSEo2UXZMRzJyc2kwRzBBVwplbEMwRisxM2xrZE5yRjJFSE9PZVA5MGpTT0EyMHZFVGd6cEltNjcxRGRnYkZoZVU1OTBvUTZTMml4V1Rsc3F2CjYwTEZSWGd0QW5VbDR4ajUwUG11eGZ5RW5zQ0duSENYbmxwVy9mc1RtMUZlUm5kenBWNmM4c2xrUjZOTlpza2YKbG5SZFdDcmRUanNROVhGSWVwYVpzdWN3alE3Y0RiTktkUTFhaUVWdXZQMUJIMHk2ckJqajZCWDE0TUoyOVlRWApYRDBSWTVuSEs5MVFlUUlEQVFBQm8wWXdSREFUQmdOVkhTVUVEREFLQmdnckJnRUZCUWNEQWpBTUJnTlZIUk1CCkFmOEVBakFBTUI4R0ExVWRJd1FZTUJhQUZFQ0dBOGFJdHBYV2E5M09JL0pQTmdhaWJ1MUNNQTBHQ1NxR1NJYjMKRFFFQkN3VUFBNElCQVFCNHhVcDNJZTg0NkpUZU9mVVd0Zmh2Wlhhdk9lbjdwQWtuZDNCeURvYlZsZFd0TjZxNQpQUlEyaWVtbGYzZm01WHdOLy9oMzBOZXRNbDFobVkrQXlzMU9CUi9GeGlzZ1ZLRjFjdm1JUk4rNWd5VnJYaW9KCjNlNU5yU3dCWkJNc3N0ZUhjRVRzcTVsT2xlMngrZEt0b1lJZk9oZHN6alZMR0dmaDJMUDYzeXBaMzhsekV4U3IKTEtjVThJTHpwUEp6alkvOElyUW5qWTRzSVUrVFh1blVnVkI5and4c2JVQVc2aHRiMXBNR3Qzc0laVk02R1FJUgo1OUhwK0lVUTd5ZGk2NU1VbGYwTlFDTjZWVXd4RDFFTHZPWWFUcS9hYkozV1ZUWVFYTGl3U3RSYVY2ZmxTNFRLCkNsSWRxVlBjbGJja3JQOWRxSFE3TXEwMTRuOGFLYit2WDdpUQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
  conditions:
  - lastTransitionTime: "2025-08-08T05:54:46Z"
    lastUpdateTime: "2025-08-08T05:54:46Z"
    message: This CSR was approved by kubectl certificate approve.
    reason: KubectlApprove
    status: "True"
    type: Approved

controlplane ~ ➜  kubectl get csr ibtisam -o jsonpath='{.status.certificate}'| base64 -d > ibtisam.crt

controlplane ~ ➜  ls
'\'   abc.yaml   ibtisam.crt   ibtisam.csr   ibtisam.key   text.txt

controlplane ~ ➜  openssl x509 -in ibtisam.crt -text -noout
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            3e:bc:22:f8:c2:66:a9:b3:e7:20:6e:4a:f0:5c:b9:37
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = kubernetes
        Validity
            Not Before: Aug  8 05:49:46 2025 GMT
            Not After : Aug  9 05:49:46 2025 GMT
        Subject: CN = ibtisam
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (3072 bit)
                Modulus:
                    00:b8:05:f7:5a:25:e5:4d:b0:9f:f2:90:fb:09:18:
                    75:2e:28:52:c3:0c:91:18:a1:96:0d:e6:82:50:35:
                    7e:55:a9:ae:2e:a9:b5:2c:58:2b:8f:59:34:b8:94:
                    51:18:b4:c6:39:d8:0e:40:4f:2c:08:24:fb:01:df:
                    16:2c:cf:34:a1:81:8a:ef:f8:d6:05:19:7d:56:5b:
                    25:69:64:f1:bf:24:5e:62:ab:70:f1:5b:5b:cf:3e:
                    99:2a:29:c8:ca:ab:02:be:25:dc:13:90:f1:ef:91:
                    ef:c0:9c:7b:87:85:24:e7:40:8e:9b:90:f3:7d:a3:
                    00:23:89:c1:64:ca:59:4f:e5:bc:97:48:4c:96:74:
                    10:b6:75:75:1b:c6:8e:71:4f:bd:12:85:c1:6c:2d:
                    31:89:15:5c:36:b9:10:36:2d:24:db:0f:9c:b8:09:
                    66:39:1d:dd:a0:04:89:19:aa:62:bd:f5:65:95:c6:
                    5d:e1:14:36:77:5a:f2:b4:fd:ad:43:2d:fe:5f:cd:
                    44:91:b6:60:f8:7c:22:82:74:dd:c1:d8:bd:f9:30:
                    81:9f:0e:0c:ec:42:c5:af:93:1c:9e:90:bc:b1:b6:
                    ae:c8:b4:1b:40:16:7a:50:b4:17:ed:77:96:47:4d:
                    ac:5d:84:1c:e3:9e:3f:dd:23:48:e0:36:d2:f1:13:
                    83:3a:48:9b:ae:f5:0d:d8:1b:16:17:94:e7:dd:28:
                    43:a4:b6:8b:15:93:96:ca:af:eb:42:c5:45:78:2d:
                    02:75:25:e3:18:f9:d0:f9:ae:c5:fc:84:9e:c0:86:
                    9c:70:97:9e:5a:56:fd:fb:13:9b:51:5e:46:77:73:
                    a5:5e:9c:f2:c9:64:47:a3:4d:66:c9:1f:96:74:5d:
                    58:2a:dd:4e:3b:10:f5:71:48:7a:96:99:b2:e7:30:
                    8d:0e:dc:0d:b3:4a:75:0d:5a:88:45:6e:bc:fd:41:
                    1f:4c:ba:ac:18:e3:e8:15:f5:e0:c2:76:f5:84:17:
                    5c:3d:11:63:99:c7:2b:dd:50:79
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Extended Key Usage: 
                TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier: 
                40:86:03:C6:88:B6:95:D6:6B:DD:CE:23:F2:4F:36:06:A2:6E:ED:42
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value:
        78:c5:4a:77:21:ef:38:e8:94:de:39:f5:16:b5:f8:6f:65:76:
        af:39:e9:fb:a4:09:27:77:70:72:0e:86:d5:95:d5:ad:37:aa:
        b9:3d:14:36:89:e9:a5:7f:77:e6:e5:7c:0d:ff:f8:77:d0:d7:
        ad:32:5d:61:99:8f:80:ca:cd:4e:05:1f:c5:c6:2b:20:54:a1:
        75:72:f9:88:44:df:b9:83:25:6b:5e:2a:09:dd:ee:4d:ad:2c:
        01:64:13:2c:b2:d7:87:70:44:ec:ab:99:4e:95:ed:b1:f9:d2:
        ad:a1:82:1f:3a:17:6c:ce:35:4b:18:67:e1:d8:b3:fa:df:2a:
        59:df:c9:73:13:14:ab:2c:a7:14:f0:82:f3:a4:f2:73:8d:8f:
        fc:22:b4:27:8d:8e:2c:21:4f:93:5e:e9:d4:81:50:7d:8f:0c:
        6c:6d:40:16:ea:1b:5b:d6:93:06:b7:7b:08:65:53:3a:19:02:
        11:e7:d1:e9:f8:85:10:ef:27:62:eb:93:14:95:fd:0d:40:23:
        7a:55:4c:31:0f:51:0b:bc:e6:1a:4e:af:da:6c:9d:d6:55:36:
        10:5c:b8:b0:4a:d4:5a:57:a7:e5:4b:84:ca:0a:52:1d:a9:53:
        dc:95:b7:24:ac:ff:5d:a8:74:3b:32:ad:35:e2:7f:1a:29:bf:
        af:5f:b8:90

controlplane ~ ➜  kubectl config set-credentials ibtisam --client-key=ibtisam.key --client-certificate=ibtisam.crt --embed-certs=true
User "ibtisam" set.

controlplane ~ ➜  kubectl config set-context ibtisam --cluster=kubernetes --user=ibtisam
Context "ibtisam" created.

controlplane ~ ➜  kubectl config view --minify --context=ibtisam
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://controlplane:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: ibtisam
  name: ibtisam
current-context: ibtisam
kind: Config
preferences: {}
users:
- name: ibtisam
  user:
    client-certificate-data: DATA+OMITTED
    client-key-data: DATA+OMITTED

controlplane ~ ➜  kubectl --context ibtisam auth whoami
ATTRIBUTE                                           VALUE
Username                                            ibtisam
Groups                                              [system:authenticated]
Extra: authentication.kubernetes.io/credential-id   [X509SHA256=959bd7f9f0dace9192911280f2fdaf1e119538b5ce2548209f18f695da0e814e]

controlplane ~ ➜  k create role ibtisam --verb=* --resource=*
role.rbac.authorization.k8s.io/ibtisam created

controlplane ~ ➜  k create rolebinding ibtisam --user=ibtisam --role=ibtisam
rolebinding.rbac.authorization.k8s.io/ibtisam created

controlplane ~ ➜  kubectl auth can-i list deployments --as ibtisam
no

controlplane ~ ✖ kubectl auth can-i list deployments --as ibtisam --context ibtisam
Error from server (Forbidden): users "ibtisam" is forbidden: User "ibtisam" cannot impersonate resource "users" in API group "" at the cluster scope

controlplane ~ ✖ kubectl auth can-i list deployments --as ibtisam --namespace default
no

controlplane ~ ✖ kubectl auth can-i --as=ibtisam --list --namespace=default
Resources                                       Non-Resource URLs   Resource Names   Verbs
*                                               []                  []               [*]
selfsubjectreviews.authentication.k8s.io        []                  []               [create]
selfsubjectaccessreviews.authorization.k8s.io   []                  []               [create]
selfsubjectrulesreviews.authorization.k8s.io    []                  []               [create]
                                                [/api/*]            []               [get]
                                                [/api]              []               [get]
                                                [/apis/*]           []               [get]
                                                [/apis]             []               [get]
                                                [/healthz]          []               [get]
                                                [/healthz]          []               [get]
                                                [/livez]            []               [get]
                                                [/livez]            []               [get]
                                                [/openapi/*]        []               [get]
                                                [/openapi]          []               [get]
                                                [/readyz]           []               [get]
                                                [/readyz]           []               [get]
                                                [/version/]         []               [get]
                                                [/version/]         []               [get]
                                                [/version]          []               [get]
                                                [/version]          []               [get]

controlplane ~ ➜  kubectl auth can-i list deployments --as ibtisam --namespace default
no

controlplane ~ ✖ k describe role ibtisam 
Name:         ibtisam
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources  Non-Resource URLs  Resource Names  Verbs
  ---------  -----------------  --------------  -----
  *          []                 []              [*]

controlplane ~ ➜  k get role ibtisam -o yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  creationTimestamp: "2025-08-08T06:02:11Z"
  name: ibtisam
  namespace: default
  resourceVersion: "5650"
  uid: a8eb0c8b-7014-4d09-bbf7-bdb8f84c5026
rules:
- apiGroups:
  - ""
  resources:
  - '*'
  verbs:
  - '*'

controlplane ~ ➜  k edit role ibtisam 
role.rbac.authorization.k8s.io/ibtisam edited

controlplane ~ ➜  k get role ibtisam -o yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  creationTimestamp: "2025-08-08T06:02:11Z"
  name: ibtisam
  namespace: default
  resourceVersion: "6676"
  uid: a8eb0c8b-7014-4d09-bbf7-bdb8f84c5026
rules:
- apiGroups:
  - ""
  - apps
  - batch
  - extensions
  resources:
  - '*'
  verbs:
  - '*'

controlplane ~ ➜  kubectl auth can-i list deployments --as ibtisam --namespace default
yes

controlplane ~ ➜  kubectl auth can-i list jobs --as ibtisam --namespace default
yes

controlplane ~ ➜   
```
