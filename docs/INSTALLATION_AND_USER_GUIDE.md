# Installation and User Guide: WordPress on Kubernetes (wp-k8s)

## 🚀 Overview

This guide provides comprehensive instructions for deploying, configuring, and maintaining the WordPress stack using the `wp-k8s` Helm chart. This solution is designed for production environments requiring high availability, persistent storage, and strict network isolation within a Kubernetes cluster.

**Goal:** To deploy a fully functional, production-grade WordPress instance backed by MySQL 8.0 and persistent storage on a Kubernetes cluster.
**Target Audience:** DevOps Engineers, Site Reliability Engineers (SREs), and System Administrators responsible for the cluster infrastructure.

---

## 📋 Prerequisites Checklist (The Foundation)

Before attempting deployment, ensure the following infrastructure components are correctly provisioned and operational:

### ⚙️ Cluster Requirements

* **Kubernetes Cluster:** Version 1.24 or newer.
* **CNI Plugin:** Cilium CNI must be installed and enabled for advanced network policy enforcement.
* **Storage Provisioner:** Local Path Provisioner must be installed and correctly configured on all worker nodes. This is critical for mapping Kubernetes volumes to physical, persistent disk locations.
* **API Gateway:** The Kubernetes Gateway API CRDs must be installed to manage ingress routing.

### 💾 Storage Prerequisites

* **HostPath Volumes:** Ensure the worker nodes have dedicated, stable physical disk locations mapped for persistent data storage. The Local Path Provisioner bridges the gap between ephemeral cluster volumes and these physical locations.

### 📦 Project Prerequisites

* **Helm:** Helm CLI installed on your local machine.
* **Configuration Files:** Access to the customer-specific GitOps manifests under `clusters/production/wordpress-instances/`.
* **Deployment Inputs:** A new instance requires three things at minimum: a customer release manifest, a customer secret manifest, and an entry in `kustomization.yaml`.

### 🔐 Required Instance Inputs

Each new WordPress instance must define the following before it can be deployed:

1. A unique customer namespace name in `cluster.customerName`.
2. A target worker node in `cluster.workerNode` that matches the local storage layout.
3. A fully qualified domain in `network.domain`.
4. Database secrets in the customer secret manifest.
5. WordPress salts and keys in the customer secret manifest.
6. The new release and secret manifests added to `kustomization.yaml` so Flux can reconcile them.

---

## 🛠️ Installation Walkthrough (Getting Started)

Follow these steps to deploy a new WordPress customer instance into your target Kubernetes cluster.

### Step 1: Prepare the Customer-Specific Manifests

The repo uses FluxCD to deploy customer instances from the files in `clusters/production/wordpress-instances/`. For a new instance, copy the existing customer manifests and update them for the new customer.

* **Action:** Copy `customer006-release.yaml` to a new release file for the customer.
* **Action:** Copy `customer006-secrets.yaml` to a new secret file for the customer.
* **Action:** Update the new release file with the customer namespace, worker node, domain, resources, autoscaling settings, and admin email.
* **Action:** Replace every `REPLACE_ME` placeholder in the secret file with real database passwords and WordPress salts/keys.

Keep the following rules in mind while editing:

* `cluster.customerName` becomes the namespace name for the instance.
* `cluster.workerNode` must point to the worker that has the expected local storage path.
* `database.secret.create` remains `false`, so the database Secret must exist before the release is reconciled.
* `wordpress.secret.name` must match the name of the WordPress secret manifest.
* `network.domain` must be the public hostname users will use to reach the site.

### Step 2: Register the Instance with Flux

After the customer manifests are ready, add both files to `clusters/production/wordpress-instances/kustomization.yaml`.

This step is required. Flux only reconciles the manifests that are listed in the kustomization file.

### Step 3: Commit and Merge the Change

Once the manifests and kustomization file are updated, commit the change and merge it to `main`.

* **Why this matters:** Flux watches the repository and applies the customer Secret resources and HelmRelease after the merge lands in `main`.
* **Operational note:** If you keep production secrets outside Git, inject them during your deployment process before Flux reconciles the release.

### Step 4: Reconcile the Cluster

Flux can apply the deployment automatically on its next interval, or you can trigger it manually.

* **Automatic:** Wait for Flux to reconcile the repository and the kustomization.
* **Manual:** Trigger a source and kustomization reconcile with Flux if you want the instance available immediately.

If you are deploying the chart manually instead of through Flux, use the release file values as the source of truth and install into the customer namespace.

```bash
helm install wordpress-customer006 ./wpk8s-stack \
  --namespace customer006 \
  --values clusters/production/wordpress-instances/customer006-release.yaml
```

### Step 5: Verification (Post-Deployment)

After deployment, verify the following resources are running and healthy:

1. **Namespace:** Confirm the customer namespace exists.

    ```bash
    kubectl get namespace customer006
    ```

2. **Secrets:** Confirm the database and WordPress secrets were created in the customer namespace.

    ```bash
    kubectl get secret -n customer006
    ```

3. **Pods:** Check that all expected pods (WordPress, MySQL) are in the `Running` state.

    ```bash
    kubectl get pods -n customer006
    ```

4. **Services:** Verify that the Service objects are correctly routing traffic.
5. **Ingress/Gateway:** Confirm that the `wordpress-httproute` object is accepting traffic and routing it to the WordPress deployment.

6. **Flux status:** Confirm the HelmRelease has reconciled successfully.

    ```bash
    kubectl get helmrelease -n flux-system
    ```

---

## ⚙️ Operational Guide (Maintenance & Scaling)

This section covers day-to-day operations, maintenance, and advanced use cases.

### Monitoring the Stack

The stack includes integrated monitoring for operational visibility:

* **Metrics:** The Apache web server runs a sidecar container that exposes Prometheus metrics via the Apache Exporter. These metrics flow through the cluster network to your central Prometheus collector.
* **Troubleshooting:** If performance issues arise, check the metrics endpoint to identify bottlenecks (e.g., high database query latency, resource exhaustion).

### Scaling and Upgrades

* **Scaling:** To scale the application (e.g., adding more WordPress replicas), modify the replica count in your values file and run `helm upgrade`.
* **Upgrades:** Always use `helm upgrade` to apply changes. This ensures Helm manages the lifecycle and handles rolling updates gracefully, minimizing downtime.

### Advanced Configuration: Deep Dive into Templates

The Helm chart uses several template files to define the cluster resources. Understanding these is key for advanced customization:

| File Path | Responsibility | When to Modify |
| :--- | :--- | :--- |
| `templates/_helpers.tpl` | Defines common variables, resource naming conventions, and shared logic used across all templates. | When you need to standardize variable definitions or introduce complex conditional logic. |
| `templates/namespace.yaml.tpl` | Defines the Kubernetes Namespace object and its lifecycle. | When deploying into a non-standard or custom namespace structure. |
| `templates/wordpress-hostpath.yaml.tpl` | Defines the volume mounts and persistence mappings for the WordPress container. **CRITICAL:** This is where physical storage mapping occurs. | When adjusting volume sizes or paths for specific hardware constraints. |
| `templates/mysql-hostpath.yaml.tpl` | Defines the volume mounts and persistence mappings for the MySQL container. **CRITICAL:** Ensures database integrity and persistent storage. | When adjusting volume sizes or paths for specific hardware constraints. |

---

## 🆘 Troubleshooting Common Issues

| Problem | Potential Cause(s) | Solution / Debug Strategy |
| :--- | :--- | :--- |
| **Pods stuck in `Pending`** | 1. Local Path Provisioner failure. 2. Insufficient cluster resources (CPU/Memory). | Check the provisioning logs for the Local Path Provisioner. Verify node availability and resource requests in your values file. |
| **Application is unreachable** | 1. Incorrect Gateway API routing. 2. Network Policy blocking ingress. | Use `kubectl describe` on the Service and Gateway objects to verify selectors and routes are correct. Check Cilium logs for dropped packets. |
| **Data loss/Corruption** | 1. HostPath volume mapping failure. 2. MySQL configuration error. | **Immediate Action:** Do not restart without diagnosis. Check the volume status and logs of both WordPress and MySQL pods to confirm data integrity before attempting recovery. |
