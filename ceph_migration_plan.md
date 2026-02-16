# Ceph Cluster Rolling Migration Plan

This document outlines the procedure for safely performing a rolling update on the cluster's nodes to replace the boot drives. This involves taking down one node at a time, performing maintenance, and bringing it back into the cluster before proceeding to the next.

> **IMPORTANT:** The key to this process is patience. Always wait for the Ceph cluster to return to a `HEALTH_OK` state before proceeding to the next major step or the next node.

---

## Phase 1: Preparation - Update Ceph Configuration

Before starting, we will modify the Ceph cluster configuration to be more explicit about which nodes and devices to use. This makes the rolling maintenance process significantly safer.

- [ ] **Modify `kubernetes/homelab-k8s-001/apps/rook-ceph/rook-ceph/cluster/helmrelease.yaml`**
  
  Update the `spec.values.cephClusterSpec.storage` section to look like the following. This changes from a blanket `useAllNodes: true` to a specific list of nodes.

  ```yaml
  storage:
    useAllNodes: false # This is the important change
    nodes:
      - name: "k8s-0"
        devicePathFilter: /dev/disk/by-id/nvme-SPCC_M.2_PCIe_SSD_*
      - name: "k8s-1"
        devicePathFilter: /dev/disk/by-id/nvme-SPCC_M.2_PCIe_SSD_*
      - name: "k8s-2"
        devicePathFilter: /dev/disk/by-id/nvme-SPCC_M.2_PCIe_SSD_*
    config:
      osdsPerDevice: "1"
  ```

- [ ] **Apply the configuration and wait for reconciliation.**
  
  Your GitOps controller (Flux) should apply this change automatically. Verify that the `CephCluster` resource in the `rook-ceph` namespace has been updated.

---

## Phase 2: Rolling Migration Loop

Perform the following steps for **each node, one at a time**. Do not start the next node until the previous one is completely finished and the cluster is healthy.

### Migrating Node `k8s-2`

#### Step 1: Cordon and Drain

- [ ] Cordon and drain the node to safely evict all running applications.

  ```sh
  kubectl drain k8s-2 --ignore-daemonsets --delete-emptydir-data
  ```

#### Step 2: Safely Remove the OSD from the Cluster

- [ ] Find the OSD ID associated with the node `k8s-2`.

  ```sh
  # Replace <tools-pod-name> with the name of your rook-ceph-tools pod
  kubectl exec -it -n rook-ceph <tools-pod-name> -- ceph osd tree
  ```
  *(Look for the `osd.X` that has `k8s-2` as its host).*

- [ ] Find the deployment name for that OSD ID.

  ```sh
  # Replace <ID> with the number from the previous step
  kubectl -n rook-ceph get deployment -l ceph-osd-id=<ID>
  ```

- [ ] Scale down the OSD deployment to 0. This tells Rook to begin the OSD removal and data migration process.

  ```sh
  # Replace <osd-deployment-name> with the name from the previous step
  kubectl -n rook-ceph patch deployment <osd-deployment-name> -p '{"spec":{"replicas":0}}'
  ```

#### Step 3: Wait for Data Migration to Complete

- [ ] **CRITICAL:** Monitor the Ceph cluster's health. Wait for it to finish rebalancing data onto the other two nodes and return to `HEALTH_OK`. The status will temporarily be `HEALTH_WARN` while data is migrating. **DO NOT PROCEED** until this step is complete.

  ```sh
  # Watch the status live from the tools pod
  kubectl exec -it -n rook-ceph <tools-pod-name> -- ceph -w
  ```

#### Step 4: Perform Node Maintenance

- [ ] Shut down node `k8s-2`.
- [ ] Physically replace the old boot SSD with the new Samsung 870 EVO.
- [ ] Reinstall Talos OS on the new boot drive.

#### Step 5: Rejoin Node and Zap NVMe Drive

- [ ] Power the node back on. Wait for it to fully boot and rejoin the Kubernetes cluster.
- [ ] Zap the NVMe drive to prepare it for use by the new OSD.

  ```sh
  # Find the name of the debugger pod on the target node
  kubectl get pods -n rook-ceph -l app=node-debugger-ds -o wide

  # Exec into the debugger pod on k8s-2 and zap the drive
  kubectl exec -it -n rook-ceph <debugger-pod-on-k8s-2> -- ceph-volume lvm zap /dev/nvme0n1 --destroy
  ```

- [ ] Uncordon the node to allow pods to be scheduled on it again.

  ```sh
  kubectl uncordon k8s-2
  ```

#### Step 6: Wait for Cluster to Heal

- [ ] **CRITICAL:** Rook will automatically create a new OSD on the zapped drive. The cluster will enter `HEALTH_WARN` as it rebalances data *onto* this new OSD. Monitor the status and wait for it to return to `HEALTH_OK`.

  ```sh
  # Watch the status live from the tools pod
  kubectl exec -it -n rook-ceph <tools-pod-name> -- ceph -w
  ```

> **Node `k8s-2` is now fully migrated!** You may now proceed to the next node.

---

### Migrating Node `k8s-1`

> Repeat the exact same steps as above, substituting `k8s-1` for `k8s-2` in all commands.

- [ ] Cordon and drain `k8s-1`.
- [ ] Safely remove the OSD for `k8s-1`.
- [ ] Wait for Ceph to become `HEALTH_OK`.
- [ ] Perform maintenance on `k8s-1`.
- [ ] Rejoin `k8s-1` and zap its NVMe drive.
- [ ] Wait for Ceph to become `HEALTH_OK`.

---

### Migrating Node `k8s-0`

> Repeat the exact same steps as above, substituting `k8s-0` for `k8s-2` in all commands.

- [ ] Cordon and drain `k8s-0`.
- [ ] Safely remove the OSD for `k8s-0`.
- [ ] Wait for Ceph to become `HEALTH_OK`.
- [ ] Perform maintenance on `k8s-0`.
- [ ] Rejoin `k8s-0` and zap its NVMe drive.
- [ ] Wait for Ceph to become `HEALTH_OK`.

---

**Migration Complete!**
