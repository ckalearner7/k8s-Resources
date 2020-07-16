# Certified Kubernetes Administrator

# Install (8%)

### Be able to install a 3-node cluster - 1 master, and 2 nodes using kubeadm

<details><summary>show</summary>
<p>

```bash
Step1: Install kubeadm, kubectl, kubelet in all the nodes
kubeadm
# At the end, kubectl get nodes - you should be able to see the 3 nodes
```
</p>
</details>


# Install the metrics server
<details><summary>show</summary>
<p>

```bash
Install metrics server
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













