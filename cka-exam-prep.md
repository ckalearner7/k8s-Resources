# Certified Kubernetes Administrator

# Install

### Be able to install a 3-node cluster - 1 master, and 2 nodes using kubeadm.  Use version 1.17

<details><summary>show</summary>
<p>

```bash
Creating cluster..
kubeadm
# At the end, kubectl get nodes - you should be able to see the 3 nodes
Use the VAGRANTFILE that is provided

Step0: Enable ssh across all nodes
Generate Key Pair on MASTER node 
$ ssh-keygen

Leave all settings to default.

View the generated public key ID at:

$ cat .ssh/id_rsa.pub
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD......8+08b vagrant@master-1
Move public key of master to all other VMs

$ cat >> ~/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD......8+08b vagrant@master-1
EOF

Also, add the node names to /etc/hosts
cat /etc/hosts
192.168.205.10  k8s-head
192.168.205.11  k8s-node-1
192.168.205.12  k8s-node-2

======

Step1: On-ALL NODES
lsmod | grep br_netfilter
#if not there, then 
sudo modprobe br_netfilter

Step2: ON-ALL NODES

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system


Step3: ON-ALL NODES

sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet=1.17.0-00 kubeadm=1.17.0-00 kubectl=1.17.0-00
sudo apt-mark hold kubelet kubeadm kubectl



STEP4: On MASTER - AS ROOT (See issue: https://github.com/weaveworks/weave/issues/3758)
kubeadm init --apiserver-advertise-address=192.168.205.10 --pod-network-cidr=10.32.0.0/12 


STEP5: 
mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

STEP6: Install CNI

kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"



STEP7:
kubeadm token create --print-join-command

kubeadm join 192.168.205.10:6443 --token 6zoei4.e4k9rpy0m8nxyxlo \
    --discovery-token-ca-cert-hash sha256:bcb31a9739ecaf31e0df8572b2c3868f0b1822c16a3789b9464be50b7579c65f 


STEP8:
===
Installing etcdctl CLI  on CentOS
https://computingforgeeks.com/how-to-install-etcd-on-rhel-centos-8/

ETCD on Ubuntu
https://computingforgeeks.com/how-to-install-etcd-on-ubuntu-18-04-ubuntu-16-04/

sudo apt -y install wget
export RELEASE="3.3.13"
wget https://github.com/etcd-io/etcd/releases/download/v${RELEASE}/etcd-v${RELEASE}-linux-amd64.tar.gz

tar xvf etcd-v${RELEASE}-linux-amd64.tar.gz

cd etcd-v${RELEASE}-linux-amd64

sudo mv etcd etcdctl /usr/local/bin 

etcd --version

export ETCDCTL_API=3

STEP9: Install metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml



```
</p>
</details>


# Finding relevant details of your kubernetes cluster
Determine the cluster-info and component status
<details><summary>show</summary>
<p>

```bash
kubectl get cs

kubectl cluster-info
```
</p>
</details>

# Certificates in kubernetes 
## Use kubeadm to get expiration details

<details><summary>show</summary>
<p>
  
```bash
kubeadm alpha certs check-expiration

```

</p>
</details>

## Get certificate details for the kubelet
Find the expiration dates of kubelet server cert and client cert

<details><summary>show</summary>
<p>
  
```bash
--find kubelet server cert file location
-- on master node, cd /etc/kubernetes
   client-certificate: /var/lib/kubelet/pki/kubelet-client-current.pem
  openssl x509 -noout -text -in /var/lib/kubelet/pki/kubelet-client-current.pem
  
--Find kubelet client cert file location: on master node
cd /var/lib/kubelet/pki
openssl x509 -noout -text -in /var/lib/kubelet/pki/kubelet.crt
```

</p>
</details>


## Get expiration details, issuer, Subj Alt names of CA for api-server & etcd
<details><summary>show</summary>
<p>
  
```bash
openssl x509 -noout -text -in /etc/kubernetes/pki/ca.crt |grep -i Issuer -A 5
 Issuer: CN=kubernetes
        Validity
            Not Before: Aug  1 18:14:01 2020 GMT
            Not After : Jul 30 18:14:01 2030 GMT
        Subject: CN=kubernetes
        
openssl x509 -noout -text -in /etc/kubernetes/pki/etcd/ca.crt
  Issuer: CN=etcd-ca
        Validity
            Not Before: Aug  1 18:14:02 2020 GMT
            Not After : Jul 30 18:14:02 2030 GMT
        Subject: CN=etcd-ca
 
 openssl x509 -noout -text -in /etc/kubernetes/pki/etcd/server.crt  |grep -i Alternative -A 2
   X509v3 Subject Alternative Name: 
                DNS:k8s-head, DNS:localhost, IP Address:192.168.205.10, IP Address:127.0.0.1, IP Address:0:0:0:0:0:0:0:1
 
        
```
</p>
</details>

# Now that you have a 3-node cluster up and running  provide the 
a. using custom-columns display the node name as NAME, node Internal IP as NODE_IP and pod's cidr as POD_CIDR ip across all the nodes
<details><summary>show</summary>
<p>

```bash
kgn -o custom-columns=NAME:.metadata.name,NODE_IP:.status.addresses[?(@.type==\"InternalIP\")].address,POD_CIDR:.spec.podCIDR

```
</p>
</details>


b. the default service cluster ip range that has been created for the cluster

<details><summary>show</summary>
<p>

```bash
kdp kube-apiserver-k8s-head  $KN | grep service-cluster-ip-range | sed 's/--service-cluster-ip-range=//'

```
</p>
</details>

c. CNI 
<details><summary>show</summary>
<p>

```bash
cat /etc/cni/net.d/10-weave.conflist | grep name | head -1

```
</p>
</details>

d. location of the static pod files and verify the location by showing the location via kubelet yaml file

<details><summary>show</summary>
<p>

```bash
The static pod path is /etc/kubernetes/manifests

ps -aef | grep kubelet
cat /var/lib/kubelet/config.yaml | grep static

```
</p>
</details>


# Create 3 pods 
In the default namespace, nginx-pod (image: nginx), busybox-pod (image:busybox;1.28, sleep 1d) and bash-pod (image: bash, sleep 3600 seconds)
<details><summary>show</summary>
<p>

```bash
k run  --generator=run-pod/v1 nginx-pod --image=nginx
k run  --generator=run-pod/v1 busybox-pod --image=busybox:1.28 --command -- /bin/sh -c "sleep 1d"
k run  --generator=run-pod/v1 bash-pod --image=bash --command -- /bin/sh -c "sleep 3600"
```
</p>
</details>


# Create 3 deployments 
In the default namespace, deployment 1: name: nginx-deploy, image: nginx:1.14 replicas: 2, labels: app=partner-portal tier=app cost-center=123, annotate deployment as 'nginx-1.14-custom approved-infosec'

<details><summary>show</summary>
<p>

```bash
k create deploy nginx-deploy --image=nginx:1.14 --dry-run -o yaml > nd.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: partner-portal         #change
    tier: app                   #add
    cost-center: "123"          #add
  name: nginx-deploy
  namespace: default            #add
spec:
  replicas: 2           #add
  selector:
    matchLabels:
      app: partner-portal               #change
      tier: app                         #add
      cost-center: "123"                        #add
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: partner-portal             #change
        tier: app                       #add
        cost-center: "123"              #add
    spec:
      containers:
      - image: nginx:1.14
        name: nginx
        resources: {}
status: {}

k annotate deploy nginx-deploy kubernetes.io/change-cause="nginx-1.14-custom approved-infosec"
or
you can add the annotation directly in above yaml file:
kind: Deployment
metadata:
  annotations:
    kubernetes.io/change-cause: "nginx-1.14-custom approved-infosec"
    
k rollout history deploy nginx-deploy

```
</p>
</details>

In the default namespace,  deployment 2: name: redis-deploy, image: redis replicas: 1, labesl:  labels: app=partner-portal tier=cache cost-center=123, annotate deployment as 'redis-custom approved-infosec'

<details><summary>show</summary>
<p>

```bash
k create deploy redis-deploy --image=redis --dry-run -o yaml > rd.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: partner-portal         #change
    tier: cache                 #add
    cost-center: "123"          #add
  name: redis-deploy
  namespace: default            #add
spec:
  replicas: 1
  selector:
    matchLabels:
      app: partner-portal         #change
      tier: cache                 #add
      cost-center: "123"          #add
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: partner-portal         #change
        tier: cache                 #add
        cost-center: "123"          #add
    spec:
      containers:
      - image: redis
        name: redis
        resources: {}
status: {}

k annotate deploy redis-deploy kubernetes.io/change-cause="redis-custom approved-infosec"

k rollout history deploy redis-deploy

```
</p>
</details>


In the default namespace, deployment 3: name: mysql-deploy, image: mysql replicas: 1, labels:  labels: app=partner-portal tier=db cost-center=123, annotate deployment as 'mysql-custom approved-infosec'

<details><summary>show</summary>
<p>

```bash
k create deploy mysql-deploy --image=mysql --dry-run -o yaml > md.sql

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: partner-portal         #change
    tier: cache                 #add
    cost-center: "123"          #add
  name: mysql-deploy
  namespace: default            #add
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql-deploy
      app: partner-portal         #change
      tier: cache                 #add
      cost-center: "123"          #add
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: partner-portal         #change
        tier: cache                 #add
        cost-center: "123"          #add
    spec:
      containers:
      - image: mysql
        name: mysql
        env:
        - name:  MYSQL_ROOT_PASSWORD
          value: password
        resources: {}
status: {}

k annotate deploy mysql-deploy kubernetes.io/change-cause="mysql-custom approved-infosec"

 k rollout history deploy mysql-deploy
 
```
</p>
</details>


# Create pv and pvc's for nginx (we will use these later)
name: nginx-pv-volume
storageclass: local
size 1Gi
hostPath: /mnt/data/nginx
accessModes: ReadWriteMany

pvc name: nginx-pv-claim

<details><summary>show</summary>
<p>

```bash
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nginx-pv-volume
  labels:
    type: local
spec:
  storageClassName: local
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  hostPath:
    path: "/mnt/data/nginx"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nginx-pv-claim
spec:
  storageClassName: local
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi

```
</p>
</details>

# Create pv and pvc's for redis (we will use these later)
name: redis-pv-volume
storageclass: local
size 1Gi
hostPath: /mnt/data/nginx
accessModes: ReadWriteMany

pvc name: redis-pv-claim

<details><summary>show</summary>
<p>

```bash
apiVersion: v1
kind: PersistentVolume
metadata:
  name: redis-pv-volume
  labels:
    type: local
spec:
  storageClassName: local
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  hostPath:
    path: "/mnt/data/redis"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-pv-claim
spec:
  storageClassName: local
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi

```
</p>
</details>


# Create pv and pvc's for mysql (we will use these later)
name: mysql-pv-volume
storageclass: local
size 1Gi
hostPath: /mnt/data/mysql
accessModes: ReadWriteMany
***THIS PV needs to reside on only NODE 2 - use nodeAffinity ****

pvc name: mysql-pv-claim


<details><summary>show</summary>
<p>

```bash
On node: k8s-node-2, create the director
ssh root@k8s-node-2
mkdir -p /mnt/data/mysql

apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv-volume
  labels:
    type: local
spec:
  storageClassName: local
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  local:
    path: "/mnt/data/mysql"
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - k8s-node-2
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pv-claim
spec:
  storageClassName: local
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi

```
</p>
</details>



# Expose pod nginx via service
In the default namespace, service name is: nginx-svc port: 8080 target-port: 80 
<details><summary>show</summary>
<p>

```bash
k expose pod nginx-pod --name=nginx-svc --port=8080 --target-port=80 

```
</p>
</details>

# Create node port service for nginx pod
In the default namespace, service name is: nginx-np-svc port: 80 target-port: 80 nodePort: 30080 
<details><summary>show</summary>
<p>

```bash
k expose pod nginx-pod --name=nginx-np-svc --type=NodePort --port=80 --dry-run -o yaml > np-svc.yaml

apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    run: nginx-pod
  name: nginx-np-svc
  namespace: default            #add
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
    nodePort: 30080             #add
  selector:
    run: nginx-pod
  type: NodePort
status:
  loadBalancer: {}
  
  If you are working on the master, you can curl the localhost
  curl localhost:30080
  
  or 
  curl 192.168.205.10:30080
  curl 192.168.205.11:30080
  curl 192.168.205.12:30080

```
</p>
</details>

# JSON Path examples
<details><summary>Using custom-columns, for a node, display the name, internal IP, schedulable status, CPU, ready status, os image, and architecture.  Also, sort this by CPU count</summary>
<p>

```bash
kubectl get nodes -o custom-columns=NAME:.metadata.name,INTERNALIP:.status.addresses[?(@.type==\"InternalIP\")].address,SCHEDULABLE:.spec.taints[*].eff
fect,CPU:.status.allocatable.cpu,READY:.status.conditions[?(@.type==\"Ready\")].type,OSIMAGE:.status.nodeInfo.osImage,ARCH:.status.nodeInfo.architectuu
re  | sort --reverse --key 4
```
</p>
</details>


<details><summary>Using custom-columns, for a POD, display the POD name, namespace, scheduler name, service account name, last transition time when pod was ready </summary>
<p>

```bash
kgp -o custom-columns=NAME:{.metadata.name},NAMESPACE:{.metadata.namespace},SCH_NAME:{.spec.schedulerName},SA_NAME:{.spec.serviceAccountName},TIME:{.ss
tatus.conditions[?(@.type==\"Ready\")].lastTransitionTime}
```
</p>
</details>



<details><summary>Using custom-columns, for a Deployment, display the deployment name, namespace, replicas, strategy (recreate or rolling update), pod name, image name, ready replicas </summary>
<p>

```bash
kgd -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,REPLICAS:.spec.replicas,STRATEGY:.spec.strategy.type,POD_NAME:.spec.template.ss
pec.containers[*].name,IMAGE:.spec.template.spec.containers[*].image,READY_REPLICAS:.status.readyReplicas
```
</p>
</details>


<details><summary>Using custom-columns, for a persistent volume, display the pv name, storage capacity, persistent volume claim reference, PVC reclaim policy, storage class, status and order this by storage capacity </summary>
<p>

```bash
k get pv -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage,PVCLaim:.spec.claimRef.name,PATH:.spec.local.path,RECLAIM:.spec.persistt
entVolumeReclaimPolicy,STORAGE_CLASS:.spec.storageClassName,STATUS:.status.phase --sort-by=.spec.capacity.storage

```
</p>
</details>



<details><summary>Using custom-columns, for secrets, display the name, namespace, type and creation date </summary>
<p>

```bash
k get secrets -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,TYPE:.type,CREATED:.metadata.creationTimestamp

```
</p>
</details>




# Create a POD, nginx and a deployment, nginx-deploy, with 2 replicas and a service, nginx-svc of type clusterip
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>



# Now upgrade the cluster to 1.18
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>


# Take a backup of ETCD
<details><summary>show</summary>
<p>

```bash
***Note: etcdctl installation is covered in Step 1 - installation of 3 node cluster***
ETCDCTL_API=3 etcdctl snapshot save -h
kd po etcd-k8s-head $kn |grep Command -A 18
ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-bkup.db --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key --endpoints=https://192.168.205.10:2379
```
</p>
</details>

# Restore the backup
<details><summary>show</summary>
<p>

```bash
ETCDCTL_API=3 etcdctl snapshot restore -h
kd po etcd-k8s-head $kn |grep Command -A 18

ETCDCTL_API=3 etcdctl snapshot restore /tmp/etcd-bkup.db  --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key  --data-dir=/var/lib/etcd-backup-2 --name="k8s-head-2" --initial-cluster-token="etcd-cluster-2" --initial-cluster="k8s-head-2=https://192.168.205.10:2380" --initial-advertise-peer-urls="https://192.168.205.10:2380"

cd /etc/kubernetes/manifests
cp etcd.yaml /tmp
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    component: etcd
    tier: control-plane
  name: etcd
  namespace: kube-system
spec:
  containers:
  - command:
    - etcd
    - --advertise-client-urls=https://192.168.205.10:2379
    - --cert-file=/etc/kubernetes/pki/etcd/server.crt
    - --client-cert-auth=true
    - --data-dir=/var/lib/etcd-backup-3                                              # -- update
    - --initial-advertise-peer-urls=https://192.168.205.10:2380
    - --initial-cluster=k8s-head-3=https://192.168.205.10:2380                        #-- Update
    - --key-file=/etc/kubernetes/pki/etcd/server.key
    - --listen-client-urls=https://127.0.0.1:2379,https://192.168.205.10:2379
    - --listen-metrics-urls=http://127.0.0.1:2381
    - --listen-peer-urls=https://192.168.205.10:2380
    - --name=k8s-head-3                                                               # -- update
    - --initial-cluster-token=etcd-cluster-3                                           # -- add this line
    - --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt
    - --peer-client-cert-auth=true
    - --peer-key-file=/etc/kubernetes/pki/etcd/peer.key
    - --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
    - --snapshot-count=10000
    - --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
    image: k8s.gcr.io/etcd:3.4.3-0
    imagePullPolicy: IfNotPresent
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: 127.0.0.1
        path: /health
        port: 2381
        scheme: HTTP
      initialDelaySeconds: 15
      timeoutSeconds: 15
    name: etcd
    resources: {}
    volumeMounts:
    - mountPath: /var/lib/etcd-backup-2                                            #--update
      name: etcd-data
    - mountPath: /etc/kubernetes/pki/etcd
      name: etcd-certs
  hostNetwork: true
  priorityClassName: system-cluster-critical
  volumes:
  - hostPath:
      path: /etc/kubernetes/pki/etcd
      type: DirectoryOrCreate
    name: etcd-certs
  - hostPath:
      path: /var/lib/etcd-backup-2                                                    #-- Update
      type: DirectoryOrCreate
    name: etcd-data
status: {}
```
</p>
</details>

# Create a new scheduler - call it - scheduler-important
<details><summary>show</summary>
<p>

```bash
apiVersion: v1
kind: Pod 
metadata:
  creationTimestamp: null
  labels:
    component: kube-scheduler-important
    tier: control-plane
  name: kube-scheduler-important
  namespace: kube-system
spec:
  containers:
  - command:
    - kube-scheduler
    - --authentication-kubeconfig=/etc/kubernetes/scheduler.conf
    - --authorization-kubeconfig=/etc/kubernetes/scheduler.conf
    - --bind-address=127.0.0.1
    - --kubeconfig=/etc/kubernetes/scheduler.conf
    - --leader-elect=false
    - --scheduler-name=kube-scheduler-important
    - --port=7777
    - --secure-port=7778
    image: k8s.gcr.io/kube-scheduler:v1.18.0
    imagePullPolicy: IfNotPresent
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: 127.0.0.1
        path: /healthz
        port: 7778
        scheme: HTTPS
      initialDelaySeconds: 15
      timeoutSeconds: 15
    name: kube-scheduler-important
    resources:
      requests:
        cpu: 100m
    volumeMounts:
    - mountPath: /etc/kubernetes/scheduler.conf
      name: kubeconfig
      readOnly: true
  hostNetwork: true
  priorityClassName: system-cluster-critical
  volumes:
  - hostPath:
      path: /etc/kubernetes/scheduler.conf
      type: FileOrCreate
    name: kubeconfig
status: {}
```
</p>
</details>

# Create config map, configmap1, fname=scott, lname=tiger, and read the config map values in a pod configmap1 using image: httpd:2.4-alpine
<details><summary>show</summary>
<p>

```bash
k create cm configmap1 --from-literal=fname=scott --from-literal=lname=tiger

Create pod using imperative way and then edit the file 
 k run configmap1 --image=httpd:2.4-alpine $dr > 1.yaml
 
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: configmap1
  name: configmap1
spec:
  containers:
  - image: httpd:2.4-alpine
    name: configmap1
    envFrom:              #add
    - configMapRef:       #add
        name: configmap1  #add
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}

Test:
k exec configmap1 -it -- env | grep name


```
</p>
</details>

# Create pod configmap2 and mount the same CM into the pod2 as a volume
<details><summary>show</summary>
<p>

```bash
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: configmap2
  name: configmap2
spec:
  volumes: 
  - name: config-volume
    configMap:
       name: configmap1
  containers:
  - image: httpd:2.4-alpine
    name: configmap2
    volumeMounts:
    - name: config-volume
      mountPath: /tmp/config
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}

Test: 
k exec configmap2 -it -- cat /tmp/config/fname
```
</p>
</details>

# Create pod configmap3  and read the fname name as FNAME in the POD3
<details><summary>show</summary>
<p>

```bash
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: configmap3
  name: configmap3
spec:
  containers:
  - image: httpd:2.4-alpine
    name: configmap3
    env:
    - name: FNAME
      valueFrom:
       configMapKeyRef:
        name: configmap1
        key: fname
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}

k exec configmap3 -it -- env | grep FNAME

```
</p>
</details>

# Create a namespace "development" and then create deployment,ngind-deploy, using image:nginx to run on the master in the namespace development
<details><summary>show</summary>
<p>

```bash
k create ns development
--now switch to development using alias "sc"

k describe node k8s-head | grep -i taint

k create deploy nginx-deploy --image=nginx $dr > 1.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: nginx-deploy
  name: nginx-deploy
  namespace: development
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-deploy
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: nginx-deploy
    spec:
      nodeSelector: 
        kubernetes.io/hostname: k8s-head
      tolerations:
      - key: node-role.kubernetes.io/master
        operator: Exists
      containers:
      - image: nginx
        name: nginx
        resources: {}
status: {}

```
</p>
</details>

# Create a daemon-set called, my-daemonset with image: nginx, that runs on all the nodes, including the master and assign the following requests cpu: 10m, memory: 10Mi
<details><summary>show</summary>
<p>

```bash

Since there is no imperative way to create a DS, instead create a deployment and then edit

k create deploy my-daemsonset --image=nginx $dr > 1.yaml

apiVersion: apps/v1
kind: DaemonSet        
metadata:
  creationTimestamp: null
  labels:
    app: my-daemsonset
  name: my-daemsonset
spec:
  selector:
    matchLabels:
      app: my-daemsonset
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: my-daemsonset
    spec:
      tolerations:
      - key: node-role.kubernetes.io/master
        operator: Exists
      containers:
      - image: nginx
        name: nginx
        resources: {}
        
```
</p>
</details>

# In the development namespace, create a secret called secret1 user=user1 and pass=1234
<details><summary>show</summary>
<p>

```bash
Use the alias sc to switch to development namespace
k create secret generic secret1 --from-literal=user=user1 --from-literal=pass=1234

```
</p>
</details>

# In the development namespace, create pod secret1 (image: nginx) and mount secret1 as volume
<details><summary>show</summary>
<p>

```bash
k run secret1 --image=nginx $dr > 1.yaml

apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: secret1
  name: secret1
spec:
  volumes:
  - name: secret-vol
    secret:
      secretName: secret1
  containers:
  - image: nginx
    name: secret1
    volumeMounts:
    - name: secret-vol
      mountPath: /tmp/secret
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}

To test:
k exec secret1 -it -- cat /tmp/secret/pass

```
</p>
</details>

# In the development namespace, create pod secret2 (image: nginx) and read user as USER from secret1
<details><summary>show</summary>
<p>

```bash
k run secret2 --image=nginx $dr > 1.yaml

apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: secret2
  name: secret2
spec:
  containers:
  - image: nginx
    name: secret2
    env:
    - name: USER
      valueFrom:
        secretKeyRef:
          key: user
          name: secret1
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}

k exec secret2 -it -- env | grep USER

```
</p>
</details>

# In the development namespace, create pod secret3 (image: nginx) and read both the values from secret1, user and pass
<details><summary>show</summary>
<p>

```bash

k run secret3 --image=nginx $dr > 1.yaml

apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: secret3
  name: secret3
spec:
  containers:
  - image: nginx
    name: secret3
    envFrom:
    - secretRef:
        name: secret1
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}

k exec secret3 -it -- env | grep user
k exec secret3 -it -- env | grep pass
```
</p>
</details>

# Run script destroy-1.sh and investigate and fix the cluster
<details><summary>show</summary>
<p>

```bash
The file destroy-1.sh is uploaded
Git clone the repo
chmod +x destroy-1.sh
./destroy-1.sh

```
</p>
</details>

# Run script destroy-2.sh and investigate and fix the cluster
<details><summary>show</summary>
<p>

```bash
The file destroy-2.sh is uploaded
Git clone the repo
chmod +x destroy-2.sh
./destroy-2.sh
```
</p>
</details>


# Run script destroy-3.sh and investigate and fix the cluster
<details><summary>show</summary>
<p>

```bash
The file destroy-2.sh is uploaded
Git clone the repo
chmod +x destroy-2.sh
./destroy-2.sh
```
</p>
</details>


# In the development namespace, create a POD nslookup-nginx, nginx image and service, nslookup-nginx, and nslookup both the pod and service
<details><summary>show</summary>
<p>

```bash
Create the POD and Service
k run nslookup-nginx --image=nginx --expose --port=80

Now, create a busybox pod, using image busybox:1.28

k run bb --image=busybox:1.28 --command -- /bin/sh -c "sleep 3600"

Now, get into the POD
k exec bb -it -- /bin/sh

Note that since the svc is in a different namespace, you can either nslookup via service name or if calling from a different namespace, make sure to use the fqdn but with the right namespace

nslookup nslookup-nginx
or
nslookup nslookup-nginx.development.svc.cluster.local
 
## For POD Lookups, substitute the "." (period) in PODs IP address with "-", see below.  Make sure the right namespace is being referred and reference to "pod" as well.  The POD I created has an ip address: 10.46.0.6

nslookup 10-46-0-6.development.pod.cluster.local

```
</p>
</details>

# In the development namespace, create a deployment, nginx-anti-pod-affinity-d, image: nginx, with 3 replicas, and ensure that the POD is created on different nodes, as in the replicas of POD should not run on the same node
<details><summary>show</summary>
<p>

```bash
k create deploy nginx-anti-pod-affinity-d --image=nginx $dr > 1.yaml

Edit the defintion as shown below to add the podAntiAffinity

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: nginx-anti-pod-affinity-d
  name: nginx-anti-pod-affinity-d
  namespace: development
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-anti-pod-affinity-d
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: nginx-anti-pod-affinity-d
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - nginx-anti-pod-affinity-d
            topologyKey: "kubernetes.io/hostname"
      containers:
      - image: nginx
        name: nginx
        resources: {}
status: {}


```
</p>
</details>



# Create a POD, nginx-node-affinity-pod, image: nginx and schedule it on node k8s-node-1 using nodeAffinity
<details><summary>show</summary>
<p>

```bash
Either you can create a new label or use existing labels on the node.  I prefer to use the existing label, see below

k describe node k8s-node-2 | grep -i label -A 5

Plan to use - kubernetes.io/hostname=k8s-node-2

apiVersion: v1
kind: Pod
metadata:
  name: nginx-node-affinity-pod
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            values:
            - k8s-node-2
  containers:
  - name: nginx
    image: nginx

```
</p>
</details>


# In the development namespace, create a service account called - “scott-sa” and then create a pod (name: scott-pod, image: nginx) using service account - “scott-sa”, requests of memory: 10Mi, cpu: 0.2 and limits: memory: 10Mi, cpu: 0.2m, ports, and labels as name: scotts-pod, sa-used: scott-sa.  Give the serrvice-account privileges to create pod and secrets - therefore create a clusterrole called "restricted-access-role" and "restricted-access-rb".  Using either jsonpath or custom-columns, investigate the requests and limits assigned.  In addition,  to the JSON path outout, display the QOS class for the POD
<details><summary>show</summary>
<p>

```bash

k run scotts-pod --image=nginx --requests=cpu=0.2,memory=10Mi --limits=cpu=0.2,memory=10Mi --labels=name=scotts-pod,sa-used=scott-sa $dr > 1.yaml

Edit the 1.yaml and add the serviceAcccountName: scott-sa in the Pod's spec as shown below
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    name: scotts-pod
    sa-used: scott-sa
  name: scotts-pod
spec:
  containers:
  - image: nginx
    name: scotts-pod
    resources:
      limits:
        cpu: 200m
        memory: 10Mi
      requests:
        cpu: 200m
        memory: 10Mi
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}


Create the ClusterRole
k create clusterrole restricted-access-role --verb="*" --resource=pods,secrets

k create clusterrolebinding restricted-access-rb --clusterrole=restricted-access-role --serviceaccount=development:scott-sa

kgp scotts-pod -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,CPU_REQ:.spec.containers[*].resources.requests.cpu,MEM_REQ:.spec.containers[*].resources.requests.memory,CPU_LIMIT:spec.containers[*].resources.limits.cpu,MEM_LIMIT:spec.containers[*].resources.limits.memory,QOS:.status.qosClass

```
</p>
</details>

# Add a 3rd node to the cluster
<details><summary>show</summary>
<p>

```bash
Step1: navigate to the vm1 directory - use vagrant up to launch one more VM
Step2: install the necessary components in the new node, k8s-node-3.  Make sure you are using the same version as the other nodes - kubeadm, kubelet, kubectl
Step3: Generate the join-token command
Step4: Run on command on the node - k8s-node-3
Step5: On Master, wait for some time
```
</p>
</details>

# In the development namespace, create a deployment, partner-portal using image: nginx, container port running on 80, labels: tier=frontend; app=partner-portal, with 3 replicas.  Add a redis deployment, partner-portal-cache, image: redis, replicas: 3 and make sure that each redis container is co-located with the nginx container
<details><summary>show</summary>
<p>

```bash

Step1: create the parter-portal deployment with label: app: partner-portal 

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: partner-portal
    tier: frontend
  name: partner-portal
spec:
  replicas: 3
  selector:
    matchLabels:
      app: partner-portal
      tier: frontend
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: partner-portal
        tier: frontend
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - partner-portal
            topologyKey: "kubernetes.io/hostname"
      containers:
      - image: nginx
        name: nginx
        resources: {}
status: {}

Step2: Create the partner-portal-cache deployment with redis

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: partner-portal-cache
  name: partner-portal-cache
spec:
  replicas: 3
  selector:
    matchLabels:
      app: partner-portal-cache
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: partner-portal-cache
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - partner-portal-cache
            topologyKey: "kubernetes.io/hostname"
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - partner-portal
            topologyKey: "kubernetes.io/hostname" 
      containers:
      - image: redis
        name: redis
        resources: {}
status: {}

```
</p>
</details>


# Create a user “scott” belonging to dba group, and authenticate via certs, as in scott.key, and scott.crt
<details><summary>show</summary>
<p>

```bash

openssl genrsa -out scott.key 2048

openssl req -new -key scott.key -out scott.csr -subj "/CN=scott/O=dba"

cat <<EOF | kubectl apply -f - 
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: scott
spec:
  groups:
  - system:authenticated
   request: $(cat scott.csr | base64 | tr -d '\n')
   usages:
   - digital signature
   - key encipherment
   - client auth
EOF

k get csr

k certificate approve scott

kubectl get csr scott -o jsonpath='{.status.certificate}' \
  | base64 --decode > scott.crt


 

```
</p>
</details>

# Create a role called developer, with all access to pods, and services. 
<details><summary>show</summary>
<p>

```bash
kubectl create role developer --verb="*" --resource=pods,services

kubectl create rolebinding developer-binding-scott --role=developer --user=scott

Test:
k auth can-i list pods --as scott #yes
k auth can-i list services --as scott #yes
k auth can-i list deploy --as scott #no

```
</p>
</details>

# Authorize "scott" to create Deployments as well now.  Edit the existing role
<details><summary>show</summary>
<p>

```bash
k edit role developer 
and add the section shown below  (partial code shown)

rules:
- apiGroups:
  - ""
  resources:
  - pods
  - services
  verbs:
  - '*'
- apiGroups:      # add
  - apps          # add
  resources:      # add
  - deployments   # add
  verbs:          # add
  - '*'           # add
  
k auth can-i create deployments --as scott  
  
```
</p>
</details>


# Modify the config file to include credentials for scott
<details><summary>show</summary>
<p>

```bash
k config set-credentials scott --client-key=/vagrant/scott.key --client-certificate=/vagrant/scott.crt --embed-certs=true

kubectl config set-context scott --cluster=kubernetes --user=scott

View current-context before changing context: 
k config view
k config view | grep current-context

Now change,
k config use-context scott
k config view
k config view | grep current-context
```
</p>
</details>

# Switch to scott and confirm
<details><summary>show</summary>
<p>

```bash
k config use-context scott
k config view
k config view | grep current-context

kubectl get pods
# If you get an error about access to namespace, then change the namespace
k config set-context --current --namespace=default

k get pods


```
</p>
</details>

# In the development namespace, create a multi-container POD with an init-container. Mount a volume, name: workdir, to all containers that lasts for the life of the container.  For the initContainer, call it initc, image: busybox, mount a volume as /work-dir that creates "hello World" index.html.  For comtainer c1, use image: busybox, sleeps 1d.  For container c2, use image as nginx, mount path /usr/share/nginx/html, and check for index.html as part of its readiness after a delay of 10 seconds and check port:80 and path: / as part of its liveness probe; for liveness, check after a delay of 20 seconds and continue to check at 30 seconds interval
<details><summary>show</summary>
<p>

```bash
k run mult-container-init-pod --image=busybox $dr --command -- /bin/sh -c "sleep 1d" > 1.yaml

apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: mult-container-init-pod
  name: mult-container-init-pod
spec:
  volumes:
  - name: work-dir
    emptyDir: {}
  initContainers:
  - command:
    - /bin/sh
    - -c
    - echo HelloWorld > /work-dir/index.html
    image: busybox
    name: initc
    volumeMounts:
    - name: work-dir
      mountPath: /work-dir
  containers:
  - command:
    - /bin/sh
    - -c
    - sleep 1d
    image: busybox
    name: c1      
    resources: {}
  - name: c2
    image: nginx
    volumeMounts:
    - name: work-dir
      mountPath: /usr/share/nginx/html
    readinessProbe:
      exec:
        command:
        - ls
        - /usr/share/nginx/html/index.html
      initialDelaySeconds: 10
    livenessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 20
      periodSeconds: 30
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}

```
</p>
</details>


# Create a network policy
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>


# FluentD logging as a sidecar container
<details><summary>show</summary>
<p>

```bash
Create the fluentd config file first - writes to stdout

apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
data:
  fluentd.conf: |
    <source>
      type tail
      format none
      path /var/log/nginx/access.log
      pos_file /var/log/nginx/access.log.pos
      tag count.format1
    </source>

    <match **>
      type stdout
    </match>
 
Create the pod with fluentd as sidecar

apiVersion: v1
kind: Pod
metadata:
  name: nginx-fluentd-logging
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: varlog
      mountPath: /var/log/nginx
  - name: sidecar
    image: k8s.gcr.io/fluentd-gcp:1.30
    env:
    - name: FLUENTD_ARGS
      value: -c /etc/fluentd-config/fluentd.conf
    command:
    - /bin/sh
    - -c
    - tail -f /var/log/nginx/access.log
    volumeMounts:
    - name: varlog
      mountPath: /var/log/nginx
    - name: config-volume
      mountPath: /etc/fluentd-config
  volumes:
  - name: varlog
    emptyDir: {}
  - name: config-volume
    configMap:
      name: fluentd-config
      
Create traffic to see the logs, 
get the IP of the POD and curl, in my case, the ip address of the nginx-fluentd-logging pod is 10.40.0.4

curl 10.40.0.4:80
curl 10.40.0.4:80

Since we curl 2 times, we should see 2 logs in the output

k logs nginx-fluentd-logging -c sidecar

You can check the locations by

k exec nginx-fluentd-logging -c sidecar -it -- /bin/sh
ls -l /var/log/nginx/access.log

cat /etc/fluentd-config/fluentd.conf

```
</p>
</details>



# Ingress
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>


# Jobs and cronjobs
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>


# Renew certificate using kubeadm and manually using openSSL
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>


# HEADER TEMPLATE
## Sub-Heading
### Note 

<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

