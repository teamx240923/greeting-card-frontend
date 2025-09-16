# 🚀 GreetingCard App Deployment Guide

## Overview

This guide covers deployment strategies for the GreetingCard app, from local development to production environments.

## Prerequisites

- Docker and Docker Compose
- Git
- Domain name (for production)
- SSL certificates (for production)
- Cloud provider account (optional)

## Local Development

### **Quick Start**
```bash
# Clone repository
git clone <repository-url>
cd greeting-card-app

# Start all services
docker-compose up -d

# Access the app
# Frontend: http://localhost:3000
# Backend API: http://localhost:8000
# API Docs: http://localhost:8000/docs
```

### **Development with Hot Reload**
```bash
# Start backend only
cd backend
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Start frontend with hot reload
cd frontend
flutter run -d chrome
```

## Docker Deployment

### **Single Container Deployment**
```bash
# Build and run
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### **Production Docker Compose**
```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  postgres:
    image: postgres:14
    environment:
      POSTGRES_DB: greetingcard_prod
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - greetingcard-network

  backend:
    image: your-registry/greetingcard-backend:latest
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/greetingcard_prod
      REDIS_URL: redis://redis:6379
      API_HOST: 0.0.0.0
      API_PORT: 8000
    depends_on:
      - postgres
      - redis
    networks:
      - greetingcard-network

  frontend:
    image: your-registry/greetingcard-frontend:latest
    ports:
      - "80:80"
    depends_on:
      - backend
    networks:
      - greetingcard-network

volumes:
  postgres_data:

networks:
  greetingcard-network:
    driver: bridge
```

## Cloud Deployment

### **AWS Deployment**

#### **1. ECS (Elastic Container Service)**
```yaml
# ecs-task-definition.json
{
  "family": "greetingcard-app",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "1024",
  "memory": "2048",
  "containerDefinitions": [
    {
      "name": "backend",
      "image": "your-account.dkr.ecr.region.amazonaws.com/greetingcard-backend:latest",
      "portMappings": [
        {
          "containerPort": 8000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "DATABASE_URL",
          "value": "postgresql://user:pass@rds-endpoint:5432/greetingcard"
        }
      ]
    }
  ]
}
```

#### **2. RDS Database Setup**
```bash
# Create RDS instance
aws rds create-db-instance \
  --db-instance-identifier greetingcard-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --master-username admin \
  --master-user-password your-password \
  --allocated-storage 20
```

#### **3. S3 Storage Setup**
```bash
# Create S3 bucket
aws s3 mb s3://greetingcard-storage

# Configure CORS
aws s3api put-bucket-cors \
  --bucket greetingcard-storage \
  --cors-configuration file://cors.json
```

### **Google Cloud Platform**

#### **1. Cloud Run Deployment**
```yaml
# cloudbuild.yaml
steps:
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/greetingcard-backend', './backend']
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/greetingcard-backend']
  - name: 'gcr.io/cloud-builders/gcloud'
    args: ['run', 'deploy', 'greetingcard-backend', '--image', 'gcr.io/$PROJECT_ID/greetingcard-backend', '--platform', 'managed', '--region', 'us-central1']
```

#### **2. Cloud SQL Setup**
```bash
# Create Cloud SQL instance
gcloud sql instances create greetingcard-db \
  --database-version=POSTGRES_14 \
  --tier=db-f1-micro \
  --region=us-central1
```

### **Azure Deployment**

#### **1. Container Instances**
```yaml
# azure-container-instance.yaml
apiVersion: 2018-10-01
location: eastus
name: greetingcard-app
properties:
  containers:
  - name: backend
    properties:
      image: your-registry.azurecr.io/greetingcard-backend:latest
      resources:
        requests:
          cpu: 1
          memoryInGb: 2
      ports:
      - port: 8000
        protocol: TCP
  osType: Linux
  ipAddress:
    type: Public
    ports:
    - protocol: TCP
      port: 8000
```

## Kubernetes Deployment

### **Namespace and ConfigMap**
```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: greetingcard

---
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: greetingcard-config
  namespace: greetingcard
data:
  DATABASE_URL: "postgresql://user:pass@postgres:5432/greetingcard"
  REDIS_URL: "redis://redis:6379"
```

### **PostgreSQL Deployment**
```yaml
# postgres-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: greetingcard
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:14
        env:
        - name: POSTGRES_DB
          value: greetingcard
        - name: POSTGRES_USER
          value: admin
        - name: POSTGRES_PASSWORD
          value: password
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
```

### **Backend Deployment**
```yaml
# backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: greetingcard
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: your-registry/greetingcard-backend:latest
        ports:
        - containerPort: 8000
        envFrom:
        - configMapRef:
            name: greetingcard-config
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
```

### **Service and Ingress**
```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: greetingcard
spec:
  selector:
    app: backend
  ports:
  - port: 8000
    targetPort: 8000
  type: ClusterIP

---
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: greetingcard-ingress
  namespace: greetingcard
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: api.greetingcard.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 8000
```

## CI/CD Pipeline

### **GitHub Actions**
```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Deploy to AWS
      run: |
        # Deploy backend
        aws ecs update-service --cluster greetingcard-cluster --service backend-service --force-new-deployment
        
        # Deploy frontend
        aws s3 sync frontend/build/web s3://greetingcard-frontend-bucket
```

### **GitLab CI/CD**
```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - deploy

build:
  stage: build
  script:
    - docker build -t $CI_REGISTRY_IMAGE/backend:$CI_COMMIT_SHA ./backend
    - docker push $CI_REGISTRY_IMAGE/backend:$CI_COMMIT_SHA

deploy:
  stage: deploy
  script:
    - kubectl set image deployment/backend backend=$CI_REGISTRY_IMAGE/backend:$CI_COMMIT_SHA
  only:
    - main
```

## Environment Configuration

### **Development**
```bash
# .env.development
DATABASE_URL=postgresql://user:pass@localhost:5432/greetingcard_dev
REDIS_URL=redis://localhost:6379
API_HOST=0.0.0.0
API_PORT=8000
DEBUG=true
```

### **Staging**
```bash
# .env.staging
DATABASE_URL=postgresql://user:pass@staging-db:5432/greetingcard_staging
REDIS_URL=redis://staging-redis:6379
API_HOST=0.0.0.0
API_PORT=8000
DEBUG=false
```

### **Production**
```bash
# .env.production
DATABASE_URL=postgresql://user:pass@prod-db:5432/greetingcard_prod
REDIS_URL=redis://prod-redis:6379
API_HOST=0.0.0.0
API_PORT=8000
DEBUG=false
```

## Monitoring and Logging

### **Application Monitoring**
```yaml
# monitoring.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
    - job_name: 'greetingcard-backend'
      static_configs:
      - targets: ['backend-service:8000']
```

### **Logging Configuration**
```yaml
# logging.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/containers/*greetingcard*.log
      pos_file /var/log/fluentd-containers.log.pos
      tag kubernetes.*
      format json
    </source>
```

## Security Considerations

### **SSL/TLS Configuration**
```nginx
# nginx.conf
server {
    listen 443 ssl http2;
    server_name api.greetingcard.com;
    
    ssl_certificate /etc/ssl/certs/greetingcard.crt;
    ssl_certificate_key /etc/ssl/private/greetingcard.key;
    
    location / {
        proxy_pass http://backend-service:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### **Secrets Management**
```yaml
# secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: greetingcard-secrets
type: Opaque
data:
  database-password: <base64-encoded-password>
  api-key: <base64-encoded-api-key>
```

## Backup and Recovery

### **Database Backup**
```bash
# Automated backup script
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME > backup_$DATE.sql
aws s3 cp backup_$DATE.sql s3://greetingcard-backups/
```

### **File Storage Backup**
```bash
# S3 backup script
aws s3 sync s3://greetingcard-storage s3://greetingcard-backups/storage/$(date +%Y%m%d)/
```

## Troubleshooting

### **Common Issues**

#### **Database Connection Issues**
```bash
# Check database connectivity
kubectl exec -it postgres-pod -- psql -U admin -d greetingcard -c "SELECT 1;"

# Check database logs
kubectl logs postgres-pod
```

#### **Backend Service Issues**
```bash
# Check backend logs
kubectl logs backend-deployment-xxx

# Check service endpoints
kubectl get endpoints backend-service
```

#### **Frontend Issues**
```bash
# Check frontend logs
kubectl logs frontend-deployment-xxx

# Check ingress configuration
kubectl describe ingress greetingcard-ingress
```

## Performance Optimization

### **Database Optimization**
```sql
-- Create indexes
CREATE INDEX idx_cards_created_at ON cards(created_at);
CREATE INDEX idx_events_user_id ON events(user_id);
CREATE INDEX idx_events_created_at ON events(created_at);
```

### **Caching Strategy**
```python
# Redis caching
@cache(expire=300)  # 5 minutes
async def get_recommendations(user_id: str):
    # Expensive computation
    pass
```

### **CDN Configuration**
```yaml
# CloudFront distribution
Resources:
  CloudFrontDistribution:
    Type: AWS::CloudFront::Distribution
    Properties:
      DistributionConfig:
        Origins:
        - DomainName: greetingcard-frontend.s3.amazonaws.com
          Id: S3Origin
          S3OriginConfig:
            OriginAccessIdentity: !Sub 'origin-access-identity/cloudfront/${CloudFrontOriginAccessIdentity}'
```

This deployment guide provides comprehensive instructions for deploying the GreetingCard app in various environments, from local development to production-scale deployments.
