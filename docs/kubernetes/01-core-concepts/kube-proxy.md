```bash
controlplane ~ ➜  k get ds -n kube-system 
NAME         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
canal        3         3         3       3            3           kubernetes.io/os=linux   110m
kube-proxy   3         3         3       3            3           kubernetes.io/os=linux   110m

controlplane ~ ➜  k get ds -n kube-system  kube-proxy -o yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  annotations:
    deprecated.daemonset.template.generation: "1"
  creationTimestamp: "2025-11-05T09:56:44Z"
  generation: 1
  labels:
    k8s-app: kube-proxy
  name: kube-proxy
  namespace: kube-system
  resourceVersion: "847"
  uid: ad9136c7-7336-496c-a5a9-527ea61cc8fc
spec:
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      k8s-app: kube-proxy
  template:
    metadata:
      labels:
        k8s-app: kube-proxy
    spec:
      containers:
      - command:
        - /usr/local/bin/kube-proxy
        - --config=/var/lib/kube-proxy/config.conf                # provided via ConfigMap
        - --hostname-override=$(NODE_NAME)
        env:
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: spec.nodeName
        image: registry.k8s.io/kube-proxy:v1.34.0
        imagePullPolicy: IfNotPresent
        name: kube-proxy
        resources: {}
        securityContext:
          privileged: true
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /var/lib/kube-proxy
          name: kube-proxy
        - mountPath: /run/xtables.lock
          name: xtables-lock
        - mountPath: /lib/modules
          name: lib-modules
          readOnly: true
      dnsPolicy: ClusterFirst
      hostNetwork: true
      nodeSelector:
        kubernetes.io/os: linux
      priorityClassName: system-node-critical
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      serviceAccount: kube-proxy
      serviceAccountName: kube-proxy
      terminationGracePeriodSeconds: 30
      tolerations:
      - operator: Exists
      volumes:
      - configMap:
          defaultMode: 420
          name: kube-proxy
        name: kube-proxy
      - hostPath:
          path: /run/xtables.lock
          type: FileOrCreate
        name: xtables-lock
      - hostPath:
          path: /lib/modules
          type: ""
        name: lib-modules
  updateStrategy:
    rollingUpdate:
      maxSurge: 0
      maxUnavailable: 1
    type: RollingUpdate
status:
  currentNumberScheduled: 3
  desiredNumberScheduled: 3
  numberAvailable: 3
  numberMisscheduled: 0
  numberReady: 3
  observedGeneration: 1
  updatedNumberScheduled: 3

controlplane ~ ➜  ls /var/lib/
apt       calico  containerd  docker  etcd  git  kubelet  misc        pam       private  rancher       sudo     ucf
buildkit  cni     dbus        dpkg    gems  k0s  man-db   PackageKit  polkit-1  python   shells.state  systemd  vim

controlplane ~ ➜  k get cm -n kube-system kube-proxy 
NAME         DATA   AGE
kube-proxy   2      115m

controlplane ~ ➜  k get cm -n kube-system kube-proxy -o yaml
apiVersion: v1
data:
  config.conf: |-
    apiVersion: kubeproxy.config.k8s.io/v1alpha1
    bindAddress: 0.0.0.0
    bindAddressHardFail: false
    clientConnection:
      acceptContentTypes: ""
      burst: 0
      contentType: ""
      kubeconfig: /var/lib/kube-proxy/kubeconfig.conf
      qps: 0
    clusterCIDR: 172.17.0.0/16
    configSyncPeriod: 0s
    conntrack:
      maxPerCore: null
      min: null
      tcpBeLiberal: false
      tcpCloseWaitTimeout: null
      tcpEstablishedTimeout: null
      udpStreamTimeout: 0s
      udpTimeout: 0s
    detectLocal:
      bridgeInterface: ""
      interfaceNamePrefix: ""
    detectLocalMode: ""
    enableProfiling: false
    healthzBindAddress: ""
    hostnameOverride: ""
    iptables:
      localhostNodePorts: null
      masqueradeAll: false
      masqueradeBit: null
      minSyncPeriod: 0s
      syncPeriod: 0s
    ipvs:
      excludeCIDRs: null
      minSyncPeriod: 0s
      scheduler: ""
      strictARP: false
      syncPeriod: 0s
      tcpFinTimeout: 0s
      tcpTimeout: 0s
      udpTimeout: 0s
    kind: KubeProxyConfiguration
    logging:
      flushFrequency: 0
      options:
        json:
          infoBufferSize: "0"
        text:
          infoBufferSize: "0"
      verbosity: 0
    metricsBindAddress: ""
    mode: ""
    nftables:
      masqueradeAll: false
      masqueradeBit: null
      minSyncPeriod: 0s
      syncPeriod: 0s
    nodePortAddresses: null
    oomScoreAdj: null
    portRange: ""
    showHiddenMetricsForVersion: ""
    winkernel:
      enableDSR: false
      forwardHealthCheckVip: false
      networkName: ""
      rootHnsEndpointName: ""
      sourceVip: ""
  kubeconfig.conf: |-
    apiVersion: v1
    kind: Config
    clusters:
    - cluster:
        certificate-authority: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        server: https://controlplane:6443
      name: default
    contexts:
    - context:
        cluster: default
        namespace: default
        user: default
      name: default
    current-context: default
    users:
    - name: default
      user:
        tokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
kind: ConfigMap
metadata:
  annotations:
    kubeadm.kubernetes.io/component-config.hash: sha256:18238492c66d85cd87676223875eea97e931abd5bf402617aac40cede13ab4d3
  creationTimestamp: "2025-11-05T09:56:43Z"
  labels:
    app: kube-proxy
  name: kube-proxy
  namespace: kube-system
  resourceVersion: "291"
  uid: 8becccc5-a854-4fa9-a11a-0f2f51e08961

controlplane ~ ➜  ls /var/lib/kube-proxy/kubeconfig.conf
ls: cannot access '/var/lib/kube-proxy/kubeconfig.conf': No such file or directory

controlplane ~ ✖ ls /var/lib/kube-proxy/config.conf
ls: cannot access '/var/lib/kube-proxy/config.conf': No such file or directory

controlplane ~ ✖ 
```
