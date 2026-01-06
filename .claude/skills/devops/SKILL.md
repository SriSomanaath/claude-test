# DevOps

Infrastructure and deployment patterns.

## Docker
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
USER 1000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0"]
```

## CI/CD (GitHub Actions)
```yaml
- name: Test
  run: pytest --cov=app

- name: Build
  run: docker build -t app:${{ github.sha }} .

- name: Deploy
  run: kubectl apply -f deployment.yaml
```

## Key Metrics
| Metric | Target |
|--------|--------|
| Uptime | 99.9% |
| Response (p95) | < 200ms |
| Error rate | < 0.1% |

## Deployment Checklist
- [ ] Tests pass
- [ ] Security scan clean
- [ ] Database migrations ready
- [ ] Rollback plan documented
