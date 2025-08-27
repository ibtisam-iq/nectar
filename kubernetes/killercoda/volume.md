controlplane:~$ k describe pvc postgres-pvc 
Name:          postgres-pvc

Events:
  Type     Reason          Age                 From                         Message     # reduce pvc size, correct pvc accessMode
  ----     ------          ----                ----                         -------
  Warning  VolumeMismatch  11s (x7 over 101s)  persistentvolume-controller  Cannot bind to requested volume "postgres-pv": requested PV is too small

  Warning  VolumeMismatch  7s (x3 over 37s)  persistentvolume-controller  Cannot bind to requested volume "postgres-pv": incompatible accessMode
