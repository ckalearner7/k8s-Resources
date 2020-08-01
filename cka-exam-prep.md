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

# Get certificate details 
Use kubeadm to get expiration details

<details><summary>show</summary>
<p>
```bash
kubeadm alpha certs check-expiration
```
</p>
</details>

# Get certificate details for the kubelet
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


# Get certificate details - find out the details of the experiration details of CA for api-server & etcd
<details><summary>show</summary>
<p>
```bash
openssl x509 -noout -text -in /etc/kubernetes/pki/ca.crt
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
Solution here.....
```
</p>
</details>

# Restore the backup
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

# Create a new scheduler - call it - scheduler-important
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

# Create CM (fname=scott, lname=tiger) and read that CM in a configmap1, image: httpd:2.4-alpine
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

# Create pod configmap2 and mount the same CM into the pod2 as a volume
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

# Create pod configmap3  and read the fname name as FNAME in the POD3
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

# Create a deployment of nginx to run on the master
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

# Create a demonset that runs on all the nodes, cpu: 10m, memory: 10Mi
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

# Create a secret called secret1 user=user1 and pass=1234
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

# Create pod secret1 and mount secret1 as volume
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

# Create pod secret2 and read user as USER from secret1
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

# Create pod secret3 and read both the values from secret1, user and pass
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

# Run script destroy-1.sh and investigate and fix the cluster
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

# Run script destroy-2.sh and investigate and fix the cluster
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>


# Run script destroy-3.sh and investigate and fix the cluster
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>


# Create a POD nslookup-nginx, nginx image and service, nslookup-svc, and nslookup both the pod and service
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

# Create a deployment with 3 replicas, and ensure that the POD is created on different nodes, as in the replicas of POD should not run on the same node
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

# Create a service account called - “scott-sa” and then using imperative way, create a pod with schedulername - “scott-sa”, requests of memory: 10Mi, cpu: 0.2 and limits: memory: 10Mi, cpu: 0.2m, ports, and labels as name: scotts-pod, sa-used: scott-sa.  Now using either jsonpath or custom-columns, investigate the requests and limits assigned.  In addition, now add the QOS class for the POD
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

# Add a 3rd node to the cluster
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

# Create a deployment with nginx, container port running on 80, labels: tier=frontend; app=partner-portal, with 3 replicas.  Add a redis container and make sure that each redis container is co-located with the nginx container
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

# Run a POD on the master
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

# Run a POD on a specific node
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

# Create a service account named, secret-admin, and provide read on secrets.  Run a pod with that specific service account, and now curl the kubernetes cluster to confirm access
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

# Create a user “scott” and authenticate via certs, as in scott.key, and scott.crt
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

# Create a role called developer, with all access to pods, services and deployments. 
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

# Authorize "scott" to create PODs, Deployments and services
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>


# Modify the config file to include credentials for scott
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

# Switch to scott and confirm
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>


# Create a service account “scott-app-sa"
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

# Create a role called frontend, with all access to pods and deployments. 
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>

# Authorize "scott-app-sa" to create PODs and Deployments
<details><summary>show</summary>
<p>

```bash
Solution here.....
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


# Create a init-container
<details><summary>show</summary>
<p>

```bash
Solution here.....
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

# Renew certificate using kubeadm and manually using openSSL
<details><summary>show</summary>
<p>

```bash
Solution here.....
```
</p>
</details>


