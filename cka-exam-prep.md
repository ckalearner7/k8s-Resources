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
solution here
```
</p>
</details>


# Get certificate details - find out the details of the experiration details of CA for api-server & etcd
<details><summary>show</summary>
<p>
```bash
solution here
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


# Expose pod nginx via service
In the default namespace, service name is: nginx-svc port: 8080 target-port: 80 
<details><summary>show</summary>
<p>

```bash
k expose pod nginx --name=nginx-svc --port=8080 --target-port=80 

```
</p>
</details>

# Create 3 deployments 
In the default namespace, deployment 1: name: nginx-deploy, image: nginx:1.14 replicas: 2, labels: app=partner-portal tier=app cost-center=123, annotate deployment as 'nginx-1.14-custom approved-infosec'

<details><summary>show</summary>
<p>

```bash
2 update......

```
</p>
</details>

In the default namespace,  deployment 2: name: redis-deploy, image: redis replicas: 1, labesl:  labels: app=partner-portal tier=cache cost-center=123, annotate deployment as 'redis-custom approved-infosec'

<details><summary>show</summary>
<p>

```bash
2 update......

```
</p>
</details>


In the default namespace, deployment 3: name: mysql-deploy, image: mysql replicas: 1, labels:  labels: app=partner-portal tier=db cost-center=123, annotate deployment as 'mysql-custom approved-infosec'

<details><summary>show</summary>
<p>

```bash
2 update......

```
</p>
</details>


# Create pv and pvc's
pv1 : name: nginx-pv, storageclass: local, size 1Gi, hostPath: /mnt/nginxpv ,  accessModes: readwriteMany
<details><summary>show</summary>
<p>

```bash
2 update......

```
</p>
</details>

# Create pv and pvc's
pv2: name: redis-pv, storageclass: local, size 1Gi, hostPath: /mnt/redispv , ..... accessModes: readwriteMany

<details><summary>show</summary>
<p>

```bash
2 update......

```
</p>
</details>


# Create pv and pvc's
pv3: name: mysql-pv, storageclass: local, size 1Gi, hostPath: /mnt/mysqlpv ,  accessModes: readwriteMany  -- ***THIS PV needs to reside on only NODE 2 - use nodeAffinity ****

<details><summary>show</summary>
<p>

```bash
2 update......

```
</p>
</details>


# Create node port service for nginx pod
In the default namespace, service name is: nginx-svc-np port: 80 target-port: 80 nodePort: 30080 
<details><summary>show</summary>
<p>

```bash
2 update......

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


