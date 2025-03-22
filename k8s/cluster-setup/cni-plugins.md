```
ubuntu@control:~$ kubectl describe node control | grep -A 10 Conditions
Conditions:
  Type                 Status  LastHeartbeatTime                 LastTransitionTime                Reason                       Message
  ----                 ------  -----------------                 ------------------                ------                       -------
  NetworkUnavailable   False   Wed, 19 Mar 2025 19:57:30 +0000   Wed, 19 Mar 2025 19:57:30 +0000   FlannelIsUp                  Flannel is running on this node
  MemoryPressure       False   Wed, 19 Mar 2025 20:13:12 +0000   Wed, 19 Mar 2025 19:36:20 +0000   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure         False   Wed, 19 Mar 2025 20:13:12 +0000   Wed, 19 Mar 2025 19:36:20 +0000   KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure          False   Wed, 19 Mar 2025 20:13:12 +0000   Wed, 19 Mar 2025 19:36:20 +0000   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready                False   Wed, 19 Mar 2025 20:13:12 +0000   Wed, 19 Mar 2025 19:36:20 +0000   KubeletNotReady              container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized
Addresses:
  InternalIP:  172.31.91.107
  Hostname:    control
ubuntu@control:~$ kubectl logs -n kube-flannel -l app=flannel
Defaulted container "kube-flannel" out of: kube-flannel, install-cni-plugin (init), install-cni (init)
Defaulted container "kube-flannel" out of: kube-flannel, install-cni-plugin (init), install-cni (init)
I0319 19:57:30.272295       1 iptables.go:226] Changing default FORWARD chain policy to ACCEPT
I0319 19:57:30.276057       1 main.go:412] Wrote subnet file to /run/flannel/subnet.env
I0319 19:57:30.276069       1 main.go:416] Running backend.
I0319 19:57:30.293227       1 vxlan_network.go:65] watching for new subnet leases
I0319 19:57:30.295224       1 main.go:437] Waiting for all goroutines to exit
I0319 19:57:30.298358       1 iptables.go:372] bootstrap done
I0319 19:57:30.298674       1 iptables.go:372] bootstrap done
I0319 20:04:47.705674       1 kube.go:490] Creating the node lease for IPv4. This is the n.Spec.PodCIDRs: [10.244.1.0/24]
I0319 20:04:47.705707       1 subnet.go:152] Batch elem [0] is { lease.Event{Type:0, Lease:lease.Lease{EnableIPv4:true, EnableIPv6:false, Subnet:ip.IP4Net{IP:0xaf40100, PrefixLen:0x18}, IPv6Subnet:ip.IP6Net{IP:(*ip.IP6)(nil), PrefixLen:0x0}, Attrs:lease.LeaseAttrs{PublicIP:0xac1f17d2, PublicIPv6:(*ip.IP6)(nil), BackendType:"vxlan", BackendData:json.RawMessage{0x7b, 0x22, 0x56, 0x4e, 0x49, 0x22, 0x3a, 0x31, 0x2c, 0x22, 0x56, 0x74, 0x65, 0x70, 0x4d, 0x41, 0x43, 0x22, 0x3a, 0x22, 0x37, 0x65, 0x3a, 0x64, 0x62, 0x3a, 0x62, 0x32, 0x3a, 0x36, 0x39, 0x3a, 0x62, 0x63, 0x3a, 0x36, 0x34, 0x22, 0x7d}, BackendV6Data:json.RawMessage(nil)}, Expiration:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), Asof:0}} }
I0319 20:04:47.705787       1 vxlan_network.go:100] Received Subnet Event with VxLan: BackendType: vxlan, PublicIP: 172.31.23.210, PublicIPv6: (nil), BackendData: {"VNI":1,"VtepMAC":"7e:db:b2:69:bc:64"}, BackendV6Data: (nil)
I0319 20:04:47.724022       1 iptables.go:125] Setting up masking rules
I0319 20:04:47.727019       1 iptables.go:226] Changing default FORWARD chain policy to ACCEPT
I0319 20:04:47.728902       1 main.go:412] Wrote subnet file to /run/flannel/subnet.env
I0319 20:04:47.728937       1 main.go:416] Running backend.
I0319 20:04:47.737285       1 vxlan_network.go:65] watching for new subnet leases
I0319 20:04:47.737337       1 subnet.go:152] Batch elem [0] is { lease.Event{Type:0, Lease:lease.Lease{EnableIPv4:true, EnableIPv6:false, Subnet:ip.IP4Net{IP:0xaf40000, PrefixLen:0x18}, IPv6Subnet:ip.IP6Net{IP:(*ip.IP6)(nil), PrefixLen:0x0}, Attrs:lease.LeaseAttrs{PublicIP:0xac1f5b6b, PublicIPv6:(*ip.IP6)(nil), BackendType:"vxlan", BackendData:json.RawMessage{0x7b, 0x22, 0x56, 0x4e, 0x49, 0x22, 0x3a, 0x31, 0x2c, 0x22, 0x56, 0x74, 0x65, 0x70, 0x4d, 0x41, 0x43, 0x22, 0x3a, 0x22, 0x64, 0x36, 0x3a, 0x35, 0x33, 0x3a, 0x35, 0x36, 0x3a, 0x65, 0x65, 0x3a, 0x64, 0x32, 0x3a, 0x34, 0x36, 0x22, 0x7d}, BackendV6Data:json.RawMessage(nil)}, Expiration:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), Asof:0}} }
I0319 20:04:47.737670       1 vxlan_network.go:100] Received Subnet Event with VxLan: BackendType: vxlan, PublicIP: 172.31.91.107, PublicIPv6: (nil), BackendData: {"VNI":1,"VtepMAC":"d6:53:56:ee:d2:46"}, BackendV6Data: (nil)
I0319 20:04:47.741087       1 main.go:437] Waiting for all goroutines to exit
I0319 20:04:47.758214       1 iptables.go:372] bootstrap done
I0319 20:04:47.758364       1 iptables.go:372] bootstrap done
ubuntu@control:~$ ip link show cni0
Device "cni0" does not exist.
ubuntu@control:~$ sudo journalctl -u kubelet --no-pager | tail -n 20
Mar 19 20:13:49 control kubelet[8922]: E0319 20:13:49.830193    8922 kubelet.go:3002] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
Mar 19 20:13:54 control kubelet[8922]: E0319 20:13:54.831149    8922 kubelet.go:3002] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
Mar 19 20:13:59 control kubelet[8922]: E0319 20:13:59.832832    8922 kubelet.go:3002] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
Mar 19 20:14:04 control kubelet[8922]: E0319 20:14:04.834049    8922 kubelet.go:3002] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
Mar 19 20:14:09 control kubelet[8922]: E0319 20:14:09.834904    8922 kubelet.go:3002] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
Mar 19 20:14:14 control kubelet[8922]: E0319 20:14:14.836212    8922 kubelet.go:3002] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
Mar 19 20:14:19 control kubelet[8922]: E0319 20:14:19.837602    8922 kubelet.go:3002] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
Mar 19 20:14:24 control kubelet[8922]: E0319 20:14:24.838687    8922 kubelet.go:3002] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
Mar 19 20:14:29 control kubelet[8922]: E0319 20:14:29.839841    8922 kubelet.go:3002] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
Mar 19 20:14:34 control kubelet[8922]: E0319 20:14:34.841717    8922 kubelet.go:3002] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
Mar 19 20:14:39 control kubelet[8922]: E0319 20:14:39.842795    8922 kubelet.go:3002] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
Mar 19 20:14:44 control kubelet[8922]: E0319 20:14:44.844650    8922 kubelet.go:3002] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
Mar 19 20:14:49 control kubelet[8922]: E0319 20:14:49.845661    8922 kubelet.go:3002] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
Mar 19 20:14:54 control kubelet[8922]: E0319 20:14:54.847884    8922 kubelet.go:3002] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
Mar 19 20:14:59 control kubelet[8922]: E0319 20:14:59.849632    8922 kubelet.go:3002] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
Mar 19 20:15:04 control kubelet[8922]: E0319 20:15:04.851617    8922 kubelet.go:3002] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
Mar 19 20:15:09 control kubelet[8922]: E0319 20:15:09.853235    8922 kubelet.go:3002] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
Mar 19 20:15:14 control kubelet[8922]: E0319 20:15:14.854361    8922 kubelet.go:3002] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
Mar 19 20:15:19 control kubelet[8922]: E0319 20:15:19.855923    8922 kubelet.go:3002] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
Mar 19 20:15:24 control kubelet[8922]: E0319 20:15:24.857197    8922 kubelet.go:3002] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
ubuntu@control:~$ ls -l /opt/cni/bin/
total 92544
-rw-r--r-- 1 root root    11357 Jan  6 16:12 LICENSE
-rw-r--r-- 1 root root     2343 Jan  6 16:12 README.md
-rwxr-xr-x 1 root root  4655178 Jan  6 16:12 bandwidth
-rwxr-xr-x 1 root root  5287212 Jan  6 16:12 bridge
-rwxr-xr-x 1 root root 12762814 Jan  6 16:12 dhcp
-rwxr-xr-x 1 root root  4847854 Jan  6 16:12 dummy
-rwxr-xr-x 1 root root  5315134 Jan  6 16:12 firewall
-rwxr-xr-x 1 root root  2835118 Mar 19 19:57 flannel
-rwxr-xr-x 1 root root  4792010 Jan  6 16:12 host-device
-rwxr-xr-x 1 root root  4060355 Jan  6 16:12 host-local
-rwxr-xr-x 1 root root  4870719 Jan  6 16:12 ipvlan
-rwxr-xr-x 1 root root  4114939 Jan  6 16:12 loopback
-rwxr-xr-x 1 root root  4903324 Jan  6 16:12 macvlan
-rwxr-xr-x 1 root root  4713429 Jan  6 16:12 portmap
-rwxr-xr-x 1 root root  5076613 Jan  6 16:12 ptp
-rwxr-xr-x 1 root root  4333422 Jan  6 16:12 sbr
-rwxr-xr-x 1 root root  3651755 Jan  6 16:12 static
-rwxr-xr-x 1 root root  4928874 Jan  6 16:12 tap
-rwxr-xr-x 1 root root  4208424 Jan  6 16:12 tuning
-rwxr-xr-x 1 root root  4868252 Jan  6 16:12 vlan
-rwxr-xr-x 1 root root  4488658 Jan  6 16:12 vrf
ubuntu@control:~$ ls -l /etc/cni/net.d/
total 4
-rw-r--r-- 1 root root 292 Mar 19 19:57 10-flannel.conflist
ubuntu@control:~$ kubectl delete -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
namespace "kube-flannel" deleted
serviceaccount "flannel" deleted
clusterrole.rbac.authorization.k8s.io "flannel" deleted
clusterrolebinding.rbac.authorization.k8s.io "flannel" deleted
configmap "kube-flannel-cfg" deleted
daemonset.apps "kube-flannel-ds" deleted
namespace/kube-flannel created
serviceaccount/flannel created
clusterrole.rbac.authorization.k8s.io/flannel created
clusterrolebinding.rbac.authorization.k8s.io/flannel created
configmap/kube-flannel-cfg created
daemonset.apps/kube-flannel-ds created
ubuntu@control:~$ sudo systemctl restart kubelet
sudo systemctl restart containerd  # or sudo systemctl restart docker (if using Docker)
ubuntu@control:~$ kubectl get nodes
kubectl get pods -n kube-flannel
ip link show cni0
NAME               STATUS   ROLES           AGE   VERSION
control            Ready    control-plane   41m   v1.32.3
ip-172-31-23-210   Ready    <none>          13m   v1.32.3
NAME                    READY   STATUS    RESTARTS   AGE
kube-flannel-ds-scr2d   1/1     Running   0          36s
kube-flannel-ds-wpghp   1/1     Running   0          36s
Device "cni0" does not exist.
ubuntu@control:~$ ip link show cni0
Device "cni0" does not exist.
ubuntu@control:~$ kubectl logs -n kube-flannel -l app=flannel
Defaulted container "kube-flannel" out of: kube-flannel, install-cni-plugin (init), install-cni (init)
Defaulted container "kube-flannel" out of: kube-flannel, install-cni-plugin (init), install-cni (init)
I0319 20:17:41.017293       1 iptables.go:125] Setting up masking rules
I0319 20:17:41.028374       1 iptables.go:226] Changing default FORWARD chain policy to ACCEPT
I0319 20:17:41.030671       1 main.go:412] Wrote subnet file to /run/flannel/subnet.env
I0319 20:17:41.030778       1 main.go:416] Running backend.
I0319 20:17:41.046871       1 vxlan_network.go:65] watching for new subnet leases
I0319 20:17:41.046901       1 subnet.go:152] Batch elem [0] is { lease.Event{Type:0, Lease:lease.Lease{EnableIPv4:true, EnableIPv6:false, Subnet:ip.IP4Net{IP:0xaf40000, PrefixLen:0x18}, IPv6Subnet:ip.IP6Net{IP:(*ip.IP6)(nil), PrefixLen:0x0}, Attrs:lease.LeaseAttrs{PublicIP:0xac1f5b6b, PublicIPv6:(*ip.IP6)(nil), BackendType:"vxlan", BackendData:json.RawMessage{0x7b, 0x22, 0x56, 0x4e, 0x49, 0x22, 0x3a, 0x31, 0x2c, 0x22, 0x56, 0x74, 0x65, 0x70, 0x4d, 0x41, 0x43, 0x22, 0x3a, 0x22, 0x64, 0x36, 0x3a, 0x35, 0x33, 0x3a, 0x35, 0x36, 0x3a, 0x65, 0x65, 0x3a, 0x64, 0x32, 0x3a, 0x34, 0x36, 0x22, 0x7d}, BackendV6Data:json.RawMessage(nil)}, Expiration:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), Asof:0}} }
I0319 20:17:41.047163       1 vxlan_network.go:100] Received Subnet Event with VxLan: BackendType: vxlan, PublicIP: 172.31.91.107, PublicIPv6: (nil), BackendData: {"VNI":1,"VtepMAC":"d6:53:56:ee:d2:46"}, BackendV6Data: (nil)
I0319 20:17:41.047668       1 main.go:437] Waiting for all goroutines to exit
I0319 20:17:41.049083       1 iptables.go:372] bootstrap done
I0319 20:17:41.049805       1 iptables.go:372] bootstrap done
I0319 20:17:40.774324       1 iptables.go:125] Setting up masking rules
I0319 20:17:40.781327       1 iptables.go:226] Changing default FORWARD chain policy to ACCEPT
I0319 20:17:40.785003       1 main.go:412] Wrote subnet file to /run/flannel/subnet.env
I0319 20:17:40.785114       1 main.go:416] Running backend.
I0319 20:17:40.797413       1 vxlan_network.go:65] watching for new subnet leases
I0319 20:17:40.797520       1 subnet.go:152] Batch elem [0] is { lease.Event{Type:0, Lease:lease.Lease{EnableIPv4:true, EnableIPv6:false, Subnet:ip.IP4Net{IP:0xaf40100, PrefixLen:0x18}, IPv6Subnet:ip.IP6Net{IP:(*ip.IP6)(nil), PrefixLen:0x0}, Attrs:lease.LeaseAttrs{PublicIP:0xac1f17d2, PublicIPv6:(*ip.IP6)(nil), BackendType:"vxlan", BackendData:json.RawMessage{0x7b, 0x22, 0x56, 0x4e, 0x49, 0x22, 0x3a, 0x31, 0x2c, 0x22, 0x56, 0x74, 0x65, 0x70, 0x4d, 0x41, 0x43, 0x22, 0x3a, 0x22, 0x37, 0x65, 0x3a, 0x64, 0x62, 0x3a, 0x62, 0x32, 0x3a, 0x36, 0x39, 0x3a, 0x62, 0x63, 0x3a, 0x36, 0x34, 0x22, 0x7d}, BackendV6Data:json.RawMessage(nil)}, Expiration:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), Asof:0}} }
I0319 20:17:40.797572       1 vxlan_network.go:100] Received Subnet Event with VxLan: BackendType: vxlan, PublicIP: 172.31.23.210, PublicIPv6: (nil), BackendData: {"VNI":1,"VtepMAC":"7e:db:b2:69:bc:64"}, BackendV6Data: (nil)
I0319 20:17:40.799448       1 main.go:437] Waiting for all goroutines to exit
I0319 20:17:40.801659       1 iptables.go:372] bootstrap done
I0319 20:17:40.817359       1 iptables.go:372] bootstrap done
ubuntu@control:~$ cat /etc/cni/net.d/10-flannel.conflist
{
  "name": "cbr0",
  "cniVersion": "0.3.1",
  "plugins": [
    {
      "type": "flannel",
      "delegate": {
        "hairpinMode": true,
        "isDefaultGateway": true
      }
    },
    {
      "type": "portmap",
      "capabilities": {
        "portMappings": true
      }
    }
  ]
}
ubuntu@control:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: enX0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP group default qlen 1000
    link/ether 12:2e:e4:29:d7:f7 brd ff:ff:ff:ff:ff:ff
    inet 172.31.91.107/20 metric 100 brd 172.31.95.255 scope global dynamic enX0
       valid_lft 2637sec preferred_lft 2637sec
    inet6 fe80::102e:e4ff:fe29:d7f7/64 scope link 
       valid_lft forever preferred_lft forever
3: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 8951 qdisc noqueue state UNKNOWN group default 
    link/ether d6:53:56:ee:d2:46 brd ff:ff:ff:ff:ff:ff
    inet 10.244.0.0/32 scope global flannel.1
       valid_lft forever preferred_lft forever
    inet6 fe80::d453:56ff:feee:d246/64 scope link 
       valid_lft forever preferred_lft forever
ubuntu@control:~$ sudo ip link delete flannel.1
ubuntu@control:~$ kubectl delete -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
namespace "kube-flannel" deleted
serviceaccount "flannel" deleted
clusterrole.rbac.authorization.k8s.io "flannel" deleted
clusterrolebinding.rbac.authorization.k8s.io "flannel" deleted
configmap "kube-flannel-cfg" deleted
daemonset.apps "kube-flannel-ds" deleted
namespace/kube-flannel created
serviceaccount/flannel created
clusterrole.rbac.authorization.k8s.io/flannel created
clusterrolebinding.rbac.authorization.k8s.io/flannel created
configmap/kube-flannel-cfg created
daemonset.apps/kube-flannel-ds created
ubuntu@control:~$ sudo systemctl restart kubelet
sudo systemctl restart containerd
ubuntu@control:~$ sudo iptables -L -v -n | grep FLANNEL
    0     0 FLANNEL-FWD  0    --  *      *       0.0.0.0/0            0.0.0.0/0            /* flanneld forward */
Chain FLANNEL-FWD (1 references)
ubuntu@control:~$ kubectl get pods -n kube-system -o wide
NAME                              READY   STATUS    RESTARTS   AGE   IP              NODE               NOMINATED NODE   READINESS GATES
coredns-668d6bf9bc-7v4qr          1/1     Running   0          45m   10.244.1.2      ip-172-31-23-210   <none>           <none>
coredns-668d6bf9bc-ghql2          1/1     Running   0          45m   10.244.1.3      ip-172-31-23-210   <none>           <none>
etcd-control                      1/1     Running   0          45m   172.31.91.107   control            <none>           <none>
kube-apiserver-control            1/1     Running   0          45m   172.31.91.107   control            <none>           <none>
kube-controller-manager-control   1/1     Running   0          45m   172.31.91.107   control            <none>           <none>
kube-proxy-78gnx                  1/1     Running   0          45m   172.31.91.107   control            <none>           <none>
kube-proxy-gf2dn                  1/1     Running   0          17m   172.31.23.210   ip-172-31-23-210   <none>           <none>
kube-scheduler-control            1/1     Running   0          45m   172.31.91.107   control            <none>           <none>
ubuntu@control:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: enX0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP group default qlen 1000
    link/ether 12:2e:e4:29:d7:f7 brd ff:ff:ff:ff:ff:ff
    inet 172.31.91.107/20 metric 100 brd 172.31.95.255 scope global dynamic enX0
       valid_lft 2501sec preferred_lft 2501sec
    inet6 fe80::102e:e4ff:fe29:d7f7/64 scope link 
       valid_lft forever preferred_lft forever
4: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 8951 qdisc noqueue state UNKNOWN group default 
    link/ether d6:53:56:ee:d2:46 brd ff:ff:ff:ff:ff:ff
    inet 10.244.0.0/32 scope global flannel.1
       valid_lft forever preferred_lft forever
    inet6 fe80::d453:56ff:feee:d246/64 scope link 
       valid_lft forever preferred_lft forever
ubuntu@control:~$ kubectl get pods -n kube-flannel -o wide
NAME                    READY   STATUS    RESTARTS   AGE    IP              NODE               NOMINATED NODE   READINESS GATES
kube-flannel-ds-9xfsd   1/1     Running   0          3m4s   172.31.91.107   control            <none>           <none>
kube-flannel-ds-m88tx   1/1     Running   0          3m4s   172.31.23.210   ip-172-31-23-210   <none>           <none>
ubuntu@control:~$ kubectl get nodes -o wide
NAME               STATUS   ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION   CONTAINER-RUNTIME
control            Ready    control-plane   48m   v1.32.3   172.31.91.107   <none>        Ubuntu 24.04.1 LTS   6.8.0-1021-aws   containerd://1.7.25
ip-172-31-23-210   Ready    <none>          19m   v1.32.3   172.31.23.210   <none>        Ubuntu 24.04.1 LTS   6.8.0-1021-aws   containerd://1.7.25
ubuntu@control:~$ kubectl run --rm -it --image=busybox busybox -- /bin/sh
If you don't see a command prompt, try pressing enter.
/ # ping nginx
PING nginx (10.98.88.224): 56 data bytes
^C
--- nginx ping statistics ---
11 packets transmitted, 0 packets received, 100% packet loss
/ # ^C

/ # exit
Session ended, resume using 'kubectl attach busybox -c busybox -i -t' command when the pod is running
pod "busybox" deleted
ubuntu@control:~$ kubectl get pods
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          18m
ubuntu@control:~$ kubectl get pods -o wide
NAME    READY   STATUS    RESTARTS   AGE   IP           NODE               NOMINATED NODE   READINESS GATES
nginx   1/1     Running   0          18m   10.244.1.4   ip-172-31-23-210   <none>           <none>
ubuntu@control:~$ kubectl run --rm -it --image=busybox busybox -- /bin/sh
If you don't see a command prompt, try pressing enter.
/ # ping 10.244.1.4
PING 10.244.1.4 (10.244.1.4): 56 data bytes
64 bytes from 10.244.1.4: seq=0 ttl=64 time=0.087 ms
64 bytes from 10.244.1.4: seq=1 ttl=64 time=0.076 ms
64 bytes from 10.244.1.4: seq=2 ttl=64 time=0.073 ms
64 bytes from 10.244.1.4: seq=3 ttl=64 time=0.073 ms
64 bytes from 10.244.1.4: seq=4 ttl=64 time=0.074 ms
64 bytes from 10.244.1.4: seq=5 ttl=64 time=0.075 ms
64 bytes from 10.244.1.4: seq=6 ttl=64 time=0.076 ms
^C
--- 10.244.1.4 ping statistics ---
7 packets transmitted, 7 packets received, 0% packet loss
round-trip min/avg/max = 0.073/0.076/0.087 ms
/ # exit
Session ended, resume using 'kubectl attach busybox -c busybox -i -t' command when the pod is running
pod "busybox" deleted
ubuntu@control:~$ sysctl net.ipv4.ip_forward
net.ipv4.ip_forward = 1
ubuntu@control:~$ ip route show
default via 172.31.80.1 dev enX0 proto dhcp src 172.31.91.107 metric 100 
10.244.1.0/24 via 10.244.1.0 dev flannel.1 onlink 
172.31.0.2 via 172.31.80.1 dev enX0 proto dhcp src 172.31.91.107 metric 100 
172.31.80.0/20 dev enX0 proto kernel scope link src 172.31.91.107 metric 100 
172.31.80.1 dev enX0 proto dhcp scope link src 172.31.91.107 metric 100 
ubuntu@control:~$ sudo systemctl restart kubelet
sudo systemctl restart containerd
ubuntu@control:~$ kubectl logs -n kube-flannel -l app=flannel
Defaulted container "kube-flannel" out of: kube-flannel, install-cni-plugin (init), install-cni (init)
Defaulted container "kube-flannel" out of: kube-flannel, install-cni-plugin (init), install-cni (init)
I0319 20:21:04.587122       1 iptables.go:125] Setting up masking rules
I0319 20:21:04.609441       1 iptables.go:226] Changing default FORWARD chain policy to ACCEPT
I0319 20:21:04.617861       1 main.go:412] Wrote subnet file to /run/flannel/subnet.env
I0319 20:21:04.617874       1 main.go:416] Running backend.
I0319 20:21:04.631570       1 main.go:437] Waiting for all goroutines to exit
I0319 20:21:04.635889       1 vxlan_network.go:65] watching for new subnet leases
I0319 20:21:04.635915       1 subnet.go:152] Batch elem [0] is { lease.Event{Type:0, Lease:lease.Lease{EnableIPv4:true, EnableIPv6:false, Subnet:ip.IP4Net{IP:0xaf40100, PrefixLen:0x18}, IPv6Subnet:ip.IP6Net{IP:(*ip.IP6)(nil), PrefixLen:0x0}, Attrs:lease.LeaseAttrs{PublicIP:0xac1f17d2, PublicIPv6:(*ip.IP6)(nil), BackendType:"vxlan", BackendData:json.RawMessage{0x7b, 0x22, 0x56, 0x4e, 0x49, 0x22, 0x3a, 0x31, 0x2c, 0x22, 0x56, 0x74, 0x65, 0x70, 0x4d, 0x41, 0x43, 0x22, 0x3a, 0x22, 0x37, 0x65, 0x3a, 0x64, 0x62, 0x3a, 0x62, 0x32, 0x3a, 0x36, 0x39, 0x3a, 0x62, 0x63, 0x3a, 0x36, 0x34, 0x22, 0x7d}, BackendV6Data:json.RawMessage(nil)}, Expiration:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), Asof:0}} }
I0319 20:21:04.636436       1 vxlan_network.go:100] Received Subnet Event with VxLan: BackendType: vxlan, PublicIP: 172.31.23.210, PublicIPv6: (nil), BackendData: {"VNI":1,"VtepMAC":"7e:db:b2:69:bc:64"}, BackendV6Data: (nil)
I0319 20:21:04.644586       1 iptables.go:372] bootstrap done
I0319 20:21:04.652765       1 iptables.go:372] bootstrap done
I0319 20:21:04.388723       1 iptables.go:125] Setting up masking rules
I0319 20:21:04.396863       1 iptables.go:226] Changing default FORWARD chain policy to ACCEPT
I0319 20:21:04.399328       1 main.go:412] Wrote subnet file to /run/flannel/subnet.env
I0319 20:21:04.399345       1 main.go:416] Running backend.
I0319 20:21:04.412566       1 vxlan_network.go:65] watching for new subnet leases
I0319 20:21:04.412698       1 subnet.go:152] Batch elem [0] is { lease.Event{Type:0, Lease:lease.Lease{EnableIPv4:true, EnableIPv6:false, Subnet:ip.IP4Net{IP:0xaf40000, PrefixLen:0x18}, IPv6Subnet:ip.IP6Net{IP:(*ip.IP6)(nil), PrefixLen:0x0}, Attrs:lease.LeaseAttrs{PublicIP:0xac1f5b6b, PublicIPv6:(*ip.IP6)(nil), BackendType:"vxlan", BackendData:json.RawMessage{0x7b, 0x22, 0x56, 0x4e, 0x49, 0x22, 0x3a, 0x31, 0x2c, 0x22, 0x56, 0x74, 0x65, 0x70, 0x4d, 0x41, 0x43, 0x22, 0x3a, 0x22, 0x64, 0x36, 0x3a, 0x35, 0x33, 0x3a, 0x35, 0x36, 0x3a, 0x65, 0x65, 0x3a, 0x64, 0x32, 0x3a, 0x34, 0x36, 0x22, 0x7d}, BackendV6Data:json.RawMessage(nil)}, Expiration:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), Asof:0}} }
I0319 20:21:04.412895       1 vxlan_network.go:100] Received Subnet Event with VxLan: BackendType: vxlan, PublicIP: 172.31.91.107, PublicIPv6: (nil), BackendData: {"VNI":1,"VtepMAC":"d6:53:56:ee:d2:46"}, BackendV6Data: (nil)
I0319 20:21:04.413505       1 main.go:437] Waiting for all goroutines to exit
I0319 20:21:04.415548       1 iptables.go:372] bootstrap done
I0319 20:21:04.419112       1 iptables.go:372] bootstrap done
ubuntu@control:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: enX0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP group default qlen 1000
    link/ether 12:2e:e4:29:d7:f7 brd ff:ff:ff:ff:ff:ff
    inet 172.31.91.107/20 metric 100 brd 172.31.95.255 scope global dynamic enX0
       valid_lft 2126sec preferred_lft 2126sec
    inet6 fe80::102e:e4ff:fe29:d7f7/64 scope link 
       valid_lft forever preferred_lft forever
4: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 8951 qdisc noqueue state UNKNOWN group default 
    link/ether d6:53:56:ee:d2:46 brd ff:ff:ff:ff:ff:ff
    inet 10.244.0.0/32 scope global flannel.1
       valid_lft forever preferred_lft forever
    inet6 fe80::d453:56ff:feee:d246/64 scope link 
       valid_lft forever preferred_lft forever
ubuntu@control:~$ cat /run/flannel/subnet.env
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.0.1/24
FLANNEL_MTU=8951
FLANNEL_IPMASQ=true
ubuntu@control:~$ ip link show flannel.1
4: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 8951 qdisc noqueue state UNKNOWN mode DEFAULT group default 
    link/ether d6:53:56:ee:d2:46 brd ff:ff:ff:ff:ff:ff
ubuntu@control:~$ ip route show
default via 172.31.80.1 dev enX0 proto dhcp src 172.31.91.107 metric 100 
10.244.1.0/24 via 10.244.1.0 dev flannel.1 onlink 
172.31.0.2 via 172.31.80.1 dev enX0 proto dhcp src 172.31.91.107 metric 100 
172.31.80.0/20 dev enX0 proto kernel scope link src 172.31.91.107 metric 100 
172.31.80.1 dev enX0 proto dhcp scope link src 172.31.91.107 metric 100 
ubuntu@control:~$ kubectl get pods -o wide
NAME    READY   STATUS    RESTARTS   AGE   IP           NODE               NOMINATED NODE   READINESS GATES
nginx   1/1     Running   0          25m   10.244.1.4   ip-172-31-23-210   <none>           <none>
ubuntu@control:~$ kubectl run --rm -it --image=busybox testpod -- /bin/sh
If you don't see a command prompt, try pressing enter.
/ # ping 10.244.1.4
PING 10.244.1.4 (10.244.1.4): 56 data bytes
64 bytes from 10.244.1.4: seq=0 ttl=64 time=0.094 ms
64 bytes from 10.244.1.4: seq=1 ttl=64 time=0.075 ms
64 bytes from 10.244.1.4: seq=2 ttl=64 time=0.086 ms
64 bytes from 10.244.1.4: seq=3 ttl=64 time=0.078 ms
^C
--- 10.244.1.4 ping statistics ---
4 packets transmitted, 4 packets received, 0% packet loss
round-trip min/avg/max = 0.075/0.083/0.094 ms
/ # exit
Session ended, resume using 'kubectl attach testpod -c testpod -i -t' command when the pod is running
pod "testpod" deleted
ubuntu@control:~$ 
````
