# ADR-001: Multi-Cloud Infrastructure Strategy

**Status:** Accepted
**Date:** January 28, 2026
**Decision Makers:** Matt Milligan

## Context

Tolling.Network is designed as an "agency-native" network where each toll agency runs its own Hyperledger Fabric peer on infrastructure they control. This mirrors the real-world structure of toll interoperability: agencies are independent organizations with their own IT policies, vendor relationships, and compliance requirements.

The legacy codebase (2019-2020) was built on GCP with hardcoded IPs and GKE-specific configurations. No documented rationale exists for this choice.

We need to decide how to structure the production infrastructure in a way that:
1. Validates the multi-cloud, agency-native architecture
2. Provides deployment guides for agencies using different cloud providers
3. Avoids vendor lock-in for the network as a whole
4. Supports gradual adoption as agencies join

## Decision

**Deploy the initial network across three cloud providers: GCP, AWS, and Azure.**

The topology:
- **Orderer nodes:** Distributed across all three clouds (Raft consensus with 5 nodes: 2 on GCP, 2 on AWS, 1 on Azure)
- **Org1 (peer):** GCP (GKE)
- **Org2 (peer):** AWS (EKS)
- **Org3 (peer):** Azure (AKS)
- **Org4 (peer):** GCP (second org on same cloud, demonstrating multi-tenant hosting)

This configuration:
- Proves cross-cloud Fabric consensus works in practice
- Generates deployment documentation for all three major clouds
- Demonstrates that agencies can choose their preferred cloud without affecting network participation
- Tests network latency and consensus performance across cloud boundaries

## Consequences

### Positive

1. **Agency flexibility** — Agencies can join using their existing cloud relationships. No single vendor lock-in.

2. **Proven multi-cloud** — We'll have battle-tested deployment guides for GKE, EKS, and AKS before the first real agency joins.

3. **Realistic latency testing** — Cross-cloud consensus will expose any latency issues that would affect production.

4. **Hub-compatible** — Regional hubs (E-ZPass, CUSIOP, SEIOP, WRTO) can each choose their own cloud or run on-premises.

5. **Distributed ordering service** — No single cloud provider can take down the ordering service. Survives regional outages.

### Negative

1. **Operational complexity** — Three sets of Terraform modules, three CI/CD pipelines, three monitoring dashboards.

2. **Cost** — Running infrastructure across three clouds is more expensive than consolidating on one.

3. **Networking complexity** — Cross-cloud connectivity requires VPN tunnels or public endpoints with mTLS. More attack surface.

4. **Skill requirements** — Team must be proficient in GKE, EKS, and AKS. Can't specialize.

### Neutral

1. **Bevel abstracts some differences** — Hyperledger Bevel supports all three managed Kubernetes services, reducing cloud-specific customization.

2. **Secret management varies** — GCP Secret Manager, AWS Secrets Manager, and Azure Key Vault have different APIs. HashiCorp Vault could unify this but adds another component.

## Implementation

### Phase 1: Infrastructure Scaffolding

Create Terraform modules for each cloud:

```
infrastructure/
├── terraform/
│   ├── modules/
│   │   ├── fabric-peer/          # Cloud-agnostic peer deployment
│   │   ├── fabric-orderer/       # Cloud-agnostic orderer deployment
│   │   └── fabric-ca/            # Cloud-agnostic CA deployment
│   ├── gcp/
│   │   ├── main.tf               # GKE cluster + Org1, Org4 peers + 2 orderers
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── aws/
│   │   ├── main.tf               # EKS cluster + Org2 peer + 2 orderers
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   └── azure/
│       ├── main.tf               # AKS cluster + Org3 peer + 1 orderer
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
```

### Phase 2: Cross-Cloud Networking

Options (to be decided in separate ADR):
1. **Public endpoints with mTLS** — Simplest. Each peer/orderer exposes a public IP with mutual TLS.
2. **VPN mesh** — More secure. GCP-AWS-Azure VPN tunnels. Higher operational overhead.
3. **Service mesh** — Most complex. Istio or Linkerd across clouds. May be overkill.

Initial recommendation: **Public endpoints with mTLS** for simplicity. Fabric already requires mTLS for peer-to-peer communication.

### Phase 3: Unified Observability

Deploy observability stack that aggregates across clouds:
- **Prometheus** federation or **Grafana Cloud** for metrics
- **Loki** or cloud-native logging (aggregated in one place)
- **Jaeger** for distributed tracing across cloud boundaries

### Phase 4: Agency Onboarding Kit

Create a "starter kit" for agencies to deploy their own peer:
- Terraform module for each cloud
- Bevel network.yaml template
- Connection profile generator
- Step-by-step guide for joining an existing channel

## Cost Estimate (Monthly)

| Component | GCP | AWS | Azure | Total |
|-----------|-----|-----|-------|-------|
| Kubernetes cluster (3-node) | $200 | $220 | $200 | $620 |
| Load balancers (2) | $40 | $40 | $40 | $120 |
| Persistent storage (100GB) | $20 | $25 | $20 | $65 |
| Egress (50GB cross-cloud) | $5 | $5 | $5 | $15 |
| **Subtotal per cloud** | **$265** | **$290** | **$265** | **$820** |

This is for development/staging. Production would require larger clusters, multi-region for HA, and backup storage.

## Alternatives Considered

### Single Cloud (GCP only)
- **Pros:** Simpler operations, lower cost, team already has GCP experience
- **Cons:** Vendor lock-in, doesn't prove agency-native architecture, agencies on AWS/Azure have no deployment guide
- **Decision:** Rejected. The core value proposition is agency independence.

### Two Clouds (GCP + AWS)
- **Pros:** Covers 80%+ of government cloud usage, reduces complexity vs. three clouds
- **Cons:** Azure has growing government market share, excludes agencies on Azure
- **Decision:** Rejected. Adding Azure is marginal additional effort and proves broader compatibility.

### On-Premises Only
- **Pros:** Maximum agency control, no cloud vendor dependency
- **Cons:** Many agencies are cloud-first, doesn't provide cloud deployment guides
- **Decision:** Not rejected, but deferred. Will add on-premises deployment guide later for agencies with data sovereignty requirements.

## References

- [Hyperledger Bevel Multi-Cloud Support](https://hyperledger-bevel.readthedocs.io/)
- [Fabric Raft Consensus](https://hyperledger-fabric.readthedocs.io/en/latest/orderer/ordering_service.html)
- plan.md Section 2 — Channel & Network Design (Option C)
