# Production-Ready High Availability Two-Tier AWS Architecture

## 🏗️ Architecture Design & Components

The complete enterprise infrastructure topology is documented visually in the `architecture.png` file below. This setup demonstrates a fault-tolerant, secure web application framework distributed across multiple Availability Zones (AZs).

![AWS Two-Tier Architecture Diagram](./images/architecture.png)

---

## 💻 Tier 1: Web & Application Layer

### 🌐 Public-Facing Routing & Compute
This layer handles initial user ingress and balances incoming traffic across scalable, self-healing application nodes.
*   **Application Load Balancer (ALB):** Positioned within the public subnets to serve as the single entry point for external client traffic. It automatically distributes incoming **HTTP (Port 80)** and **HTTPS (Port 443)** traffic across active compute nodes.
*   **Auto Scaling Group (ASG):** Orchestrates high availability by dynamically managing EC2 instance counts across **Availability Zone 1 (AZ-1)** and **Availability Zone 2 (AZ-2)** to seamlessly absorb traffic spikes or compute failures.
*   **Web Security Group (Web SG):** Acts as a virtual firewall for the application layer, strictly configured to **Allow only HTTP/S (80/443)** inbound traffic from the public internet.

---

## 🗄️ Tier 2: Database Layer

### 🔒 Private Data Segregation
This layer isolates critical backend storage from direct internet exposure while providing automated failover mechanisms.
*   **Isolated Private Subnets:** All database assets are intentionally deployed within isolated private subnets, ensuring zero public IP assignments and eliminating direct ingress paths from the internet.
*   **Amazon RDS Multi-AZ Deployment:** Configured with an active **RDS Primary (Master) Instance** in **AZ-1** that continuously runs **Synchronous Replication** to an **RDS Standby (Replica) Instance** in **AZ-2**. This provides high-availability disaster recovery with automatic **DNS Failover**.
*   **Database Security Group (DB SG):** Enforces a strict network perimeter by utilizing rule-chaining to **Allow only DB port traffic** originating explicitly from the **Web SG** tier.

---

## 🛡️ Applied Security Boundaries

### ⚡ Principle of Least Privilege
*   **Network Segregation:** Traffic cannot bypass the Application Load Balancer to hit the EC2 instances directly, and the database tier completely rejects any communication not initiated by the application nodes.
*   **Structural Redundancy:** By splitting resources across distinct geographical Availability Zones, the architecture guarantees minimal downtime and eliminates single points of failure (SPOFs).
--------------------------------------------------------------------------------------------------------------------------------------------

## 🌐 Phase 1: Networking & Security Infrastructure

### 🗺️ Virtual Private Cloud (VPC) Initialization
The foundational network layer was established by provisioning a custom Virtual Private Cloud (VPC) named `two-tier-vpc`. This isolated network boundary hosts the entire compute and database fleet.

#### ⚙️ Core VPC Configurations:
* **VPC ID:** `vpc-0bc429a390f01a23a`
* **IPv4 CIDR Block:** `10.0.0.0/16` (Provides `65,536` available private IP addresses for scalable subnetting)
* **DNS Settings:** `DNS resolution` has been explicitly **Enabled** to ensure internal AWS service endpoints can resolve seamlessly.
* **Tenancy:** Configured as **Default** to run on shared hardware, optimizing cost efficiency.

![VPC Dashboard Configuration](./images/vpc.png)

----------------------------------------------------------------------------------------------------------------------------------------------

### 🗺️ Subnet Segmentation & IP Strategy

To enforce tight network isolation, the `two-tier-vpc` was segmented into four distinct subnets across multiple Availability Zones. This layout physically isolates public-facing web routing from private data storage nodes.

#### 📊 Subnet Configuration Directory

| Subnet Name | Subnet ID | Availability Zone | IPv4 CIDR Block | Auto-Assign Public IPv4 | Role / Layer |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **public-subnet-1a** | `subnet-09eae50295f40d4e4` | `us-east-1a` | `10.0.1.0/24` | **Enabled** | Presentation (ALB / Ingress) |
| **public-subnet-1b** | `subnet-025173b470af3d709` | `us-east-1b` | `10.0.2.0/24` | **Enabled** | Presentation (ALB / Ingress) |
| **private-subnet-1a** | `subnet-0ec7218f7587dac14` | `us-east-1a` | `10.0.11.0/24` | **Disabled** | Persistent Data (Amazon RDS) |
| **private-subnet-1b** | `subnet-01579d1af9cf8e451` | `us-east-1b` | `10.0.12.0/24` | **Disabled** | Persistent Data (Amazon RDS) |

![VPC Subnets Configuration](./images/subnets.png)

#### ⚙️ Engineering Implementation Details:
* **Public Subnets (`10.0.1.0/24` & `10.0.2.0/24`):** Configured with `MapPublicIpOnLaunch` set to **True** (Enable auto-assign public IP address). This allows the Application Load Balancer endpoints to obtain valid public IPv4 addresses for internet-facing routing.
* **Private Subnets (`10.0.11.0/24` & `10.0.12.0/24`):** Kept with `MapPublicIpOnLaunch` set to **False** (Disable auto-assign public IP address). This creates a strict security boundary by ensuring that no resources provisioned within this database layer are reachable or viewable from external networks.