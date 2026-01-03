# Design Document: Web Application Hosting Infrastructure

## Overview

This design document outlines a comprehensive, cloud-native web application hosting infrastructure for a one-man digital startup. The solution leverages AWS services in a multi-region architecture with sa-east-1 as the primary region and us-east-1 for global services. The infrastructure provides a modern Kubernetes platform with service mesh capabilities, GitOps deployment workflows, and comprehensive observability.

The architecture follows cloud-native best practices with Infrastructure as Code (Terraform using official AWS community modules), containerized workloads (EKS), service mesh (Istio), GitOps (ArgoCD), and a complete observability stack (Prometheus, Grafana, Kiali). This design enables rapid application development and deployment while maintaining enterprise-grade security, reliability, and cost optimization.

**Module Strategy:** The infrastructure leverages proven, community-maintained Terraform modules from the terraform-aws-modules organization to ensure best practices, reduce maintenance overhead, and benefit from community contributions and security updates.

## Architecture

### High-Level Architecture

```mermaid
graph TB
    subgraph "Global Services (us-east-1)"
        CF[CloudFront CDN]
        ACM[ACM Certificates]
        R53[Route 53 DNS]
    end
    
    subgraph "Primary Region (sa-east-1)"
        subgraph "VPC"
            subgraph "Public Subnets"
                ALB[Application Load Balancer]
                NAT[NAT Gateway]
            end
            
            subgraph "Private Subnets"
                subgraph "EKS Cluster"
                    subgraph "Control Plane"
                        API[EKS API Server]
                    end
                    
                    subgraph "Worker Nodes"
                        subgraph "Istio System"
                            IG[Istio Gateway]
                            IC[Istio Control Plane]
                        end
                        
                        subgraph "Application Pods"
                            APP1[App 1 + Sidecar]
                            APP2[App 2 + Sidecar]
                        end
                        
                        subgraph "GitOps"
                            ARGO[ArgoCD]
                            ROLLOUTS[Argo Rollouts]
                        end
                        
                        subgraph "Observability"
                            PROM[Prometheus]
                            GRAF[Grafana]
                            KIALI[Kiali]
                        end
                    end
                end
                
                RDS[(RDS PostgreSQL)]
            end
        end
        
        S3[S3 Buckets]
    end
    
    USER[Users] --> CF
    CF --> ALB
    ALB --> IG
    IG --> APP1
    IG --> APP2
    APP1 --> RDS
    APP2 --> RDS
    
    ARGO --> APP1
    ARGO --> APP2
    ROLLOUTS --> APP1
    ROLLOUTS --> APP2
    
    PROM --> APP1
    PROM --> APP2
    GRAF --> PROM
    KIALI --> IC
```

### Regional Distribution

**Primary Region (sa-east-1):**
- EKS cluster with all application workloads
- RDS PostgreSQL database
- VPC with public/private subnets
- Application Load Balancer
- S3 buckets for application data

**Global Services Region (us-east-1):**
- CloudFront distributions for global content delivery
- ACM certificates for CloudFront and ALB
- Route 53 hosted zones for DNS management

## Components and Interfaces

### 1. Network Infrastructure

**VPC Configuration (using terraform-aws-modules/vpc/aws):**
- CIDR: 10.0.0.0/16
- Public subnets: 10.0.1.0/24, 10.0.2.0/24 (across 2 AZs)
- Private subnets: 10.0.10.0/24, 10.0.20.0/24 (across 2 AZs)
- Database subnets: 10.0.100.0/24, 10.0.200.0/24 (across 2 AZs)

**Module Benefits:**
- Proven subnet calculations and CIDR management
- Automatic NAT Gateway and Internet Gateway configuration
- Built-in database subnet group creation
- Comprehensive tagging and naming conventions

**Security Groups:**
- EKS Control Plane SG: Allows API access from worker nodes
- EKS Worker Node SG: Allows cluster communication and ALB traffic
- RDS SG: Allows PostgreSQL access only from EKS worker nodes
- ALB SG: Allows HTTP/HTTPS from internet

**Routing:**
- Public subnets route to Internet Gateway
- Private subnets route to NAT Gateway for outbound access (one per AZ for HA)
- Database subnets isolated with no internet access

### 2. EKS Cluster Configuration

**Cluster Specifications:**
- Kubernetes version: 1.28+
- Managed node groups with auto-scaling
- Instance types: t3.medium (cost-optimized for startup)
- Min nodes: 2, Max nodes: 10
- Spot instances enabled for cost optimization

**Add-ons:**
- AWS Load Balancer Controller for ALB integration
- EBS CSI Driver for persistent storage
- CoreDNS for cluster DNS
- kube-proxy for network proxy

**RBAC Configuration:**
- Cluster admin access via IAM roles
- Service accounts with IRSA (IAM Roles for Service Accounts)
- Namespace-based access controls

### 3. Istio Service Mesh

**Installation Method:**
- Helm-based installation for better lifecycle management
- Istio Operator for configuration management
- Ambient mesh profile for reduced resource overhead

**Components:**
- **Istiod**: Control plane for configuration and certificate management
- **Istio Gateway**: Ingress gateway for external traffic
- **Envoy Sidecars**: Automatic injection for application pods
- **Istio Proxy**: Service mesh data plane

**Configuration:**
- mTLS enabled by default for all service-to-service communication
- Traffic policies for load balancing and circuit breaking
- Security policies for authentication and authorization
- Telemetry configuration for metrics and tracing

### 4. GitOps with ArgoCD and Argo Rollouts

**ArgoCD Configuration:**
- Deployed in dedicated `argocd` namespace
- Git repository integration for application manifests
- Multi-environment support (dev/prod)
- RBAC integration with Kubernetes

**Argo Rollouts Configuration:**
- Custom resource definitions for advanced deployment strategies
- Integration with Istio for traffic splitting
- Prometheus integration for automated analysis
- Notification webhooks for deployment events

**Deployment Strategies:**
- **Canary Deployments**: Gradual traffic shifting (10% → 50% → 100%)
- **Blue-Green Deployments**: Instant traffic switching with rollback capability
- **Analysis Templates**: Automated success/failure determination based on metrics

### 5. Observability Stack

**Prometheus Configuration:**
- Deployed via Helm chart (kube-prometheus-stack)
- Service discovery for Kubernetes and Istio metrics
- Custom metrics from application pods
- Alert rules for infrastructure and application health
- 30-day retention for metrics

**Grafana Configuration:**
- Pre-configured dashboards for Kubernetes and Istio
- Custom dashboards for application metrics
- Alert notification channels (email, Slack)
- User authentication and authorization

**Kiali Configuration:**
- Service mesh topology visualization
- Traffic flow analysis and health monitoring
- Configuration validation for Istio resources
- Integration with Prometheus for metrics display

### 6. Database Services

**RDS PostgreSQL Configuration:**
- Engine version: PostgreSQL 15+
- Instance class: db.t3.micro (cost-optimized)
- Multi-AZ deployment for high availability
- Automated backups with 7-day retention
- Encryption at rest with AWS managed keys

**Connection Management:**
- Connection pooling via PgBouncer sidecar
- Database credentials stored in AWS Secrets Manager
- Network isolation in private subnets

### 7. Content Delivery and Storage

**CloudFront Configuration:**
- Global edge locations for content delivery
- Origin: S3 buckets and ALB
- SSL/TLS termination with ACM certificates
- Caching policies optimized for web applications
- Compression enabled for bandwidth optimization

**S3 Configuration (using terraform-aws-modules/s3-bucket/aws):**
- **Assets Bucket**: Static assets with intelligent tiering
- **Backups Bucket**: Application backups with lifecycle policies
- Versioning enabled for data protection
- Server-side encryption with AWS managed keys
- Intelligent tiering for automatic cost optimization
- Lifecycle rules for backup retention (30d → IA, 90d → Glacier, 365d → Delete)

**Module Benefits:**
- Comprehensive security configurations (block public access)
- Built-in encryption and versioning management
- Lifecycle policy templates for cost optimization
- Consistent naming and tagging

### 8. Load Balancing

**Application Load Balancer:**
- Internet-facing ALB in public subnets
- SSL termination with ACM certificates
- Health checks for target groups
- Integration with AWS Load Balancer Controller
- Request routing based on host headers and paths

**Istio Gateway Integration:**
- ALB forwards traffic to Istio Gateway service
- Istio handles internal routing and load balancing
- Support for multiple applications via virtual services

## Data Models

### Infrastructure State Management

**Terraform State:**
- Remote state stored in Terraform Cloud
- State locking for concurrent operations
- Workspace separation for environments
- Sensitive values encrypted

**Kubernetes Resources:**
```yaml
# Application Deployment with Istio
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: web-app
spec:
  replicas: 3
  strategy:
    canary:
      steps:
      - setWeight: 10
      - pause: {duration: 30s}
      - setWeight: 50
      - pause: {duration: 30s}
      trafficRouting:
        istio:
          virtualService:
            name: web-app-vs
          destinationRule:
            name: web-app-dr
```

**Istio Configuration:**
```yaml
# Virtual Service for Traffic Management
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: web-app-vs
spec:
  hosts:
  - web-app.example.com
  gateways:
  - istio-gateway
  http:
  - route:
    - destination:
        host: web-app
        subset: stable
      weight: 90
    - destination:
        host: web-app
        subset: canary
      weight: 10
```

### Monitoring Data Models

**Prometheus Metrics:**
- Infrastructure metrics: CPU, memory, network, disk
- Application metrics: Request rate, error rate, duration
- Istio metrics: Service mesh traffic and security
- Custom business metrics via application instrumentation

**Alert Definitions:**
```yaml
# High Error Rate Alert
- alert: HighErrorRate
  expr: rate(istio_requests_total{response_code!~"2.."}[5m]) > 0.1
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High error rate detected"
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

Now I need to analyze the acceptance criteria to determine which ones can be tested as properties:

### Converting EARS to Properties

Based on the prework analysis, I'll convert the testable acceptance criteria into universally quantified properties:

**Property 1: Traffic Routing and Load Distribution**
*For any* incoming traffic to the infrastructure, the system should route public traffic through public subnets and distribute application traffic evenly across healthy instances
**Validates: Requirements 1.4, 2.1**

**Property 2: Security Group Access Control**
*For any* network connection attempt between components, the system should allow only necessary traffic as defined by security group rules and deny all other traffic
**Validates: Requirements 1.6**

**Property 3: Load Balancer Failover**
*For any* application instance that becomes unhealthy, the load balancer should automatically exclude it from traffic distribution and route all traffic to remaining healthy instances
**Validates: Requirements 2.2**

**Property 4: Container Autoscaling**
*For any* change in application load (increase or decrease), the container service should automatically adjust the number of running pods to match demand while minimizing costs
**Validates: Requirements 3.2, 3.3, 8.6**

**Property 5: Zero-Downtime Deployments**
*For any* application version update, the container service should deploy the new version using rolling updates without causing service interruption
**Validates: Requirements 3.4**

**Property 6: Service Mesh Sidecar Injection**
*For any* application pod deployed in the mesh-enabled namespace, the service mesh should automatically inject a sidecar proxy
**Validates: Requirements 3.8**

**Property 7: End-to-End Encryption**
*For any* data transmission within the infrastructure, the system should encrypt all communication using TLS 1.2 or higher and mTLS for service-to-service communication
**Validates: Requirements 3.9, 7.2**

**Property 8: Database Access Control**
*For any* connection attempt to the database service, access should be allowed only from application containers and denied from all other sources
**Validates: Requirements 4.3**

**Property 9: CDN Caching and Delivery**
*For any* static asset request, the CDN service should cache the content at edge locations and deliver it with compression enabled
**Validates: Requirements 5.1, 5.5**

**Property 10: Cache Invalidation**
*For any* static content update, the CDN service should invalidate the cached version within 5 minutes
**Validates: Requirements 5.4**

**Property 11: Certificate Auto-Renewal**
*For any* SSL/TLS certificate approaching expiration, the certificate service should automatically renew it before expiration
**Validates: Requirements 6.4**

**Property 12: Storage Intelligent Tiering**
*For any* data stored in the storage service, the system should automatically move infrequently accessed data to cheaper storage classes based on access patterns
**Validates: Requirements 8.3**

**Property 13: Comprehensive Logging**
*For any* API call, access attempt, or load balancer request, the system should generate and store audit logs for security and debugging purposes
**Validates: Requirements 7.5, 9.5**

**Property 14: Metrics Collection and Alerting**
*For any* infrastructure or application component, the observability stack should collect metrics and send alerts when critical thresholds are exceeded
**Validates: Requirements 9.1, 9.7**

**Property 15: GitOps Synchronization**
*For any* change committed to the Git repository, the GitOps service should automatically detect and sync the changes to the target environment
**Validates: Requirements 10.2**

**Property 16: Progressive Delivery Strategies**
*For any* application deployment using canary or blue-green strategy, the GitOps service should manage traffic shifting and automatically rollback on failure based on success metrics
**Validates: Requirements 10.7, 10.8**

**Property 17: Manifest Validation**
*For any* Kubernetes manifest submitted for deployment, the GitOps service should validate the configuration before applying it to the cluster
**Validates: Requirements 10.9**

**Property 18: Deployment Event Notifications**
*For any* deployment event (success, failure, rollback), the GitOps service should send notifications to configured channels
**Validates: Requirements 10.11**

**Property 19: Health-Based Rollback**
*For any* deployment that fails health checks or violates success metrics, the GitOps service should automatically trigger a rollback to the previous stable version
**Validates: Requirements 10.12**

## Error Handling

### Infrastructure Failures

**EKS Cluster Failures:**
- Node failures handled by auto-scaling groups replacing unhealthy nodes
- Control plane failures managed by AWS with automatic failover
- Pod failures handled by Kubernetes with automatic restart and rescheduling

**Database Failures:**
- RDS Multi-AZ provides automatic failover to standby instance
- Connection failures handled by application retry logic with exponential backoff
- Backup and restore procedures for disaster recovery

**Network Failures:**
- Multiple availability zones provide redundancy for network failures
- NAT Gateway failures handled by deploying across multiple AZs
- Load balancer health checks remove unhealthy targets automatically

### Application Failures

**Deployment Failures:**
- Argo Rollouts provides automatic rollback on failed health checks
- Blue-green deployments allow instant rollback to previous version
- Canary deployments limit blast radius of failed deployments

**Service Mesh Failures:**
- Circuit breaker patterns prevent cascade failures
- Retry policies with exponential backoff for transient failures
- Timeout configurations prevent hanging requests

**Monitoring and Alerting:**
- Dead man's switch alerts for monitoring system failures
- Multi-channel alerting (email, Slack) for redundancy
- Escalation policies for critical alerts

### Security Incident Response

**Access Control Violations:**
- Immediate alert generation for unauthorized access attempts
- Automatic IP blocking for repeated violations
- Audit trail preservation for forensic analysis

**Certificate Expiration:**
- Automated renewal with 30-day advance warning
- Fallback procedures for manual certificate management
- Monitoring for certificate validation failures

## Testing Strategy

### Dual Testing Approach

The testing strategy employs both unit tests and property-based tests to ensure comprehensive coverage:

**Unit Tests:**
- Validate specific infrastructure configurations and integrations
- Test concrete examples of deployment scenarios
- Verify error conditions and edge cases
- Focus on integration points between AWS services

**Property-Based Tests:**
- Verify universal properties across all inputs using randomized testing
- Test system behavior under various load conditions
- Validate security and compliance requirements across all scenarios
- Ensure correctness properties hold for any valid configuration

### Property-Based Testing Configuration

**Testing Framework:** 
- **Terraform**: Use Terratest for infrastructure property testing
- **Kubernetes**: Use property-based testing with generated workloads and configurations
- **Minimum 100 iterations** per property test to ensure statistical confidence

**Test Execution:**
- Each property test references its corresponding design document property
- Tag format: **Feature: web-application-hosting, Property {number}: {property_text}**
- Automated execution in CI/CD pipeline before infrastructure changes

**Test Categories:**

1. **Infrastructure Properties:**
   - Network routing and security group validation
   - Auto-scaling behavior under load variations
   - High availability and failover scenarios

2. **Security Properties:**
   - Encryption validation for all data paths
   - Access control verification across all components
   - Certificate lifecycle management

3. **Deployment Properties:**
   - Zero-downtime deployment validation
   - Progressive delivery strategy verification
   - Rollback mechanism testing

4. **Observability Properties:**
   - Metrics collection completeness
   - Alert generation accuracy
   - Log aggregation and retention

### Integration Testing

**End-to-End Scenarios:**
- Complete application deployment lifecycle
- Multi-service communication through service mesh
- Disaster recovery and backup procedures
- Performance testing under realistic load conditions

**Chaos Engineering:**
- Random node termination to test resilience
- Network partition simulation
- Resource exhaustion scenarios
- Security breach simulation

The combination of unit tests and property-based tests provides comprehensive validation that the infrastructure meets all requirements while maintaining reliability and security under all conditions.