# High-Availability Multi-AZ Web Infrastructure on AWS

## Architectural Overview
I architected and deployed a highly available, fault-tolerant, and secure multi-tier web infrastructure on AWS. The core design principles of this project focus on **network isolation**, **eliminating single points of failure**, and **elastic scalability** to handle dynamic web traffic seamlessly.

---

## System Architecture Diagram

Below is the visual blueprint of the infrastructure I designed:

## System Architecture Diagram

Below is the visual blueprint of the infrastructure I designed:

![Infrastructure Architecture Diagram](images/architecture.png)

---

## Infrastructure Breakdown (Step-by-Step)

### 1. Networking & Security Perimeter
* **Custom VPC Configuration:** I initiated the project by provisioning a custom Virtual Private Cloud (VPC) spanning across two separate **Availability Zones (AZs)** to guarantee high availability.
* **Subnet Isolation:** To enforce data security, I segmented each AZ into:
  * **Public Subnets:** Engineered strictly to house public-facing components and routing mechanisms.
  * **Private Subnets:** Isolated environments where the actual application servers reside, completely hidden from the public internet.
* **Secure Egress & Internal Routing:**
  * I deployed a **NAT Gateway** in each public subnet, enabling private servers to safely download patches and dependencies without exposing them to inbound threats.
  * I established an **S3 VPC Gateway Endpoint** to allow direct, private communication between the network and Amazon S3 without routing traffic through the public internet.

### 2. Traffic Management & Distribution
* **Application Load Balancer (ALB):** I deployed a public-facing ALB across the public subnets. 
* **Role:** It acts as the single point of entry for user traffic, intelligently distributing incoming HTTP/HTTPS requests across the backend instances in both AZs, ensuring efficient resource utilization and automatic failover.

### 3. Elastic Compute & Micro-Segmentation
* **Auto Scaling Group (ASG):** I configured an ASG across the private subnets to automate the lifecycle of the application servers.
  * **Scalability:** The ASG dynamically launches or terminates instances based on traffic demand, ensuring performance stability while optimizing infrastructure costs.
* **Security Groups (Stateful Firewalls):** I implemented strict firewall rules. The application servers are locked down to reject all direct internet traffic—they exclusively accept inbound traffic originating from the ALB’s designated security group.

----------------------------------------------------------------------------------------------------------------------------------------------

### 1. Production Virtual Private Cloud (VPC) Provisioning
* **Resource Configured:** `Prod-VPC`
* **VPC ID:** `vpc-018e4178356e21c7`
* **Primary IPv4 CIDR Block:** `10.0.0.0/16`

To build the foundation of this isolated infrastructure, I provisioned a dedicated, non-default Virtual Private Cloud named **Prod-VPC**. I assigned it a primary IPv4 CIDR block of **10.0.0.0/16**, yielding a theoretical maximum pool of $65,536$ private IP addresses ($2^{16}$). This massive address space provides ample room for deep network tiering, offering horizontal scalability as the underlying microservice fleets or subnets expand. 

![Production VPC Dashboard Configuration](images/prod-vpc.png)

**Key Configuration Details:**
* **DNS Settings:** I explicitly verified that **DNS Resolution** is `Enabled` to ensure resources inside the network can resolve AWS service endpoints smoothly.
* **Tenancy:** Left at `Default` to run workloads on shared, cost-effective physical hardware while maintaining logical isolation at the software layer.

----------------------------------------------------------------------------------------------------------------------------------------------

### 2. Multi-AZ Subnet Segmentation
To establish strict network boundaries and high availability, I partitioned the VPC's IP allocation into four distinct subnets distributed symmetrically across two Availability Zones (`us-east-1a` and `us-east-1b`).

* **Public Web Tier (Ingress):**
  * `public-subnet-1a` | ID: `subnet-04e075486b3671cd8` | CIDR: `10.0.1.0/24`
  * `public-subnet-1b` | ID: `subnet-07192e179b75c499c` | CIDR: `10.0.2.0/24`
* **Private Application Tier (Compute Workloads):**
  * `private-subnet-1a` | ID: `subnet-05f65a8e70585deb9` | CIDR: `10.0.11.0/24`
  * `private-subnet-1b` | ID: `subnet-03ca1022b3062d664` | CIDR: `10.0.12.0/24`

![VPC Subnets Configuration](images/subnets.png)

**Architectural Sizing Decisions:**
Each tier utilizes a `/24` subnet mask, allocating up to 251 usable IP addresses per subnet (accounting for AWS's 5 reserved internal IPs). This provides an optimal balance between minimizing address wastage and ensuring enough network capacity for auto-scaling events within our private runtime layer.

----------------------------------------------------------------------------------------------------------------------------------------------