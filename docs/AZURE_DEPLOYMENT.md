# Azure Deployment Guide for FoodHawk Platform

This guide explains how to deploy the FoodHawk Platform to Microsoft Azure using Terraform.

## Prerequisites

- Azure CLI installed and configured
- Terraform 1.0+ installed
- An Azure account with appropriate permissions
- Docker installed (for building images locally)

## Architecture Overview

The Azure deployment uses:
- **Azure Container Registry (ACR)**: Docker image storage
- **Azure Container Apps**: Serverless container hosting (similar to AWS ECS Fargate)
- **Azure Database for PostgreSQL**: Managed PostgreSQL database
- **Azure Resource Group**: Logical grouping of resources

## Deployment Steps

### 1. Authenticate with Azure

```bash
az login
```

### 2. Configure Terraform for Azure

Navigate to the terraform directory:

```bash
cd terraform
```

### 3. Set Up Variables

Copy the example variables file and customize it:

```bash
cp azure-terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:
- `db_username`: Database admin username
- `db_password`: Strong password for database
- `secret_key`: JWT secret key (generate a secure random string)

### 4. Initialize Terraform

```bash
terraform init -upgrade
```

### 5. Plan the Deployment

Review what resources will be created:

```bash
terraform plan -var-file="terraform.tfvars"
```

### 6. Apply the Configuration

Create the Azure resources:

```bash
terraform apply -var-file="terraform.tfvars"
```

Type `yes` when prompted to confirm.

### 7. Build and Push Docker Images

After Terraform completes, you'll need to build and push your Docker images to Azure Container Registry.

First, get the ACR login server and credentials:

```bash
ACR_LOGIN_SERVER=$(terraform output -raw container_registry_url)
ACR_USERNAME=$(terraform output -raw container_registry_username)
ACR_PASSWORD=$(az acr credential show --name $(echo $ACR_LOGIN_SERVER | cut -d. -f1) --query passwords[0].value -o tsv)
```

Login to ACR:

```bash
az acr login --name $(echo $ACR_LOGIN_SERVER | cut -d. -f1)
```

Build and push the backend image:

```bash
cd ../backend
docker build -t ${ACR_LOGIN_SERVER}/foodhawk-backend:latest .
docker push ${ACR_LOGIN_SERVER}/foodhawk-backend:latest
```

Build and push the frontend image:

```bash
cd ../frontend
docker build -t ${ACR_LOGIN_SERVER}/foodhawk-frontend:latest .
docker push ${ACR_LOGIN_SERVER}/foodhawk-frontend:latest
cd ..
```

### 8. Update Container Apps

After pushing images, update the container apps to use the new images:

```bash
az containerapp update \
  --name foodhawk-backend \
  --resource-group $(terraform output -raw resource_group_name) \
  --image ${ACR_LOGIN_SERVER}/foodhawk-backend:latest

az containerapp update \
  --name foodhawk-frontend \
  --resource-group $(terraform output -raw resource_group_name) \
  --image ${ACR_LOGIN_SERVER}/foodhawk-frontend:latest
```

### 9. Access Your Application

Get the URLs:

```bash
echo "Frontend URL: https://$(terraform output -raw frontend_url)"
echo "Backend URL: https://$(terraform output -raw backend_url)"
```

## Resource Costs

The Azure resources created have the following estimated costs (varies by region):

- Container Registry (Basic): ~$5/month
- Container Apps (pay per usage): ~$0.000018/vCPU-second, $0.0000025/GB-second
- PostgreSQL (B_Standard_B1s): ~$15-25/month
- Bandwidth: Varies by traffic

## Monitoring and Logs

View container app logs:

```bash
az containerapp logs show \
  --name foodhawk-backend \
  --resource-group $(terraform output -raw resource_group_name) \
  --follow
```

View metrics in Azure Portal:
1. Navigate to your Container App
2. Go to "Metrics" section
3. Select metrics like CPU, Memory, Requests

## Scaling

The Container Apps are configured with:
- Min replicas: 1
- Max replicas: 10
- Auto-scaling based on HTTP requests

You can modify scaling rules in the Terraform configuration.

## Database Management

Connect to the database:

```bash
az postgres flexible-server execute \
  --name $(terraform output -raw database_hostname | cut -d. -f1) \
  --resource-group $(terraform output -raw resource_group_name) \
  --database-name foodhawk \
  --admin-user $(grep db_username terraform.tfvars | cut -d'"' -f2) \
  --admin-password $(grep db_password terraform.tfvars | cut -d'"' -f2) \
  --command "SELECT * FROM users;"
```

## Cleanup

To remove all Azure resources:

```bash
cd terraform
terraform destroy -var-file="terraform.tfvars"
```

## Troubleshooting

### Container App Not Starting

Check logs:
```bash
az containerapp logs show --name foodhawk-backend --resource-group $(terraform output -raw resource_group_name) --follow
```

### Database Connection Issues

1. Verify firewall rules allow access
2. Check database credentials in Terraform variables
3. Ensure database is in the same region as container apps

### Image Pull Errors

1. Verify images were pushed to ACR
2. Check ACR credentials are correct
3. Ensure image names match Terraform configuration

## CI/CD Integration

For automated deployments, you can integrate with GitHub Actions:

1. Add Azure credentials as GitHub secrets:
   - `AZURE_CLIENT_ID`
   - `AZURE_CLIENT_SECRET`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`

2. Create a workflow that:
   - Builds Docker images
   - Pushes to ACR
   - Runs Terraform apply
   - Updates container apps

## Security Best Practices

1. Use Azure Key Vault for secrets instead of Terraform variables
2. Enable managed identities for container apps
3. Use private endpoints for database access
4. Enable Azure Defender for Cloud
5. Implement network security groups

## Next Steps

- Set up custom domain with SSL certificate
- Configure Application Insights for monitoring
- Implement Azure DevOps pipelines
- Set up staging/production environments
- Configure backup and disaster recovery
