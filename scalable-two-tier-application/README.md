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