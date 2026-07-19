# Deployment

Hush starts with a local Docker-based development environment and can later move to AWS-managed infrastructure.

## Local Development

Initial local services:

- Backend gateway
- PostgreSQL
- Redis

Expected command after project initialization:

```text
docker compose up
```

## Cloud Direction

Recommended long-term target:

- AWS ECS or EKS for services
- RDS PostgreSQL
- ElastiCache Redis
- Secrets Manager
- CloudFront where appropriate
- OpenTelemetry for traces and metrics
- GitHub Actions for CI/CD

## CI/CD Baseline

```text
Push code
  -> tests
  -> security scan
  -> build
  -> deploy
```

Security checks should be part of the pipeline from the first production-facing service onward.
