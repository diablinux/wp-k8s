# Repository Overview: wp-k8s

## 1. Project Architecture

- **Structure:**
  The project follows a Helm chart structure (`wpk8s/`) designed to deploy a complete, isolated WordPress stack onto a Kubernetes cluster. The architecture is highly focused on production readiness, isolation, and persistence in a clustered environment.
- **Core Components:**
  - **WordPress Deployment**: Runs the WordPress application (v6.8.3) using an Apache web server and includes a sidecar for Prometheus metrics collection (Apache Exporter).
  - **MySQL StatefulSet**: Provides the backend database service, ensuring stable network identities and persistent storage for MySQL 8.0 data.
  - **Persistent Storage**: Utilizes `HostPath` volumes combined with the Kubernetes Local Path Provisioner to map ephemeral cluster storage to physical, persistent disk locations on specific worker nodes.
  - **Network Policy**: Implements Cilium-based network policies to enforce strict access control, isolating services and restricting metrics exposure.
- **Data Flow:**
  Client traffic enters via the Gateway API CRDs (`wordpress-httproute.yaml.tpl`), reaching the Apache ingress, which routes requests to the WordPress container. All application data is persisted via `HostPath` volumes mapped to local storage on dedicated worker nodes. Metrics flow from the WordPress/Apache sidecar through the cluster network to Prometheus collectors.

## 2. Technical Stack

- **Backend:**
  - **Orchestration**: Kubernetes (v1.24+)
  - **Deployment Tooling**: Helm Charts (`wpk8s/`)
  - **Database**: MySQL 8.0 (deployed via StatefulSet)
  - **Web Server**: Apache HTTP Server
  - **Storage Provisioning**: Local Path Provisioner (for persistent volume claims)
  - **Networking/Security**: Cilium CNI, Kubernetes Network Policies, Gateway API CRDs.
- **Frontend:**
  The frontend is the WordPress application itself, served via Apache and accessed through the Kubernetes ingress controller.
- **Infrastructure:**
  The deployment relies heavily on physical infrastructure setup: a Kubernetes cluster with specific worker nodes, Local Path Provisioner installed and configured, and Cilium CNI enabled for advanced network policy enforcement.

## 3. Key Features & Functionality

- **Primary Use Cases:**
  - Deploying dedicated, isolated WordPress instances per customer (`customer001`, `customer002`).
  - Providing production-grade persistence for both the WordPress content and the MySQL database.
  - Monitoring: Integrated Prometheus metrics collection via Apache Exporter for operational visibility into the stack.
- **Integration Points:**
  - Kubernetes Cluster API (Deployments, StatefulSets, Services).
  - Local Path Provisioner (for physical storage integration).
  - Cilium CNI (for advanced network segmentation and security).

## 4. Development Guidelines

- **Patterns & Practices:**
  The project follows a declarative, infrastructure-as-code pattern using Helm templates (`templates/`) and configuration values (`values.example.yaml`, `values-customerXXX.yaml`). The use of `HostPath` volumes and Local Path Provisioner is a critical pattern for achieving high-performance, node-local persistence in a cluster.
- **Testing Approach:**
  While not explicitly detailed, the structure implies testing should involve applying manifests to a staging cluster and verifying resource utilization, persistence integrity, and network policy enforcement.

## 5. Getting Started

- **Setup Requirements:**
  1. Kubernetes Cluster (v1.24+) operational.
  2. Local Path Provisioner installed and configured on all worker nodes.
  3. Cilium CNI plugin enabled with network policy support.
  4. Gateway API CRDs installed.
- **Key Resources:**
  - `README.md`: High-level overview and deployment guide.
  - `TEMPLATE.md`: Detailed template setup instructions.
  - `vars.example.yaml`: Example variables file for customization.
