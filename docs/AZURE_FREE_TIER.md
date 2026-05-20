# Azure Free Tier Deployment Guide for FoodHawk Platform

This guide explains how to deploy the FoodHawk Platform to Azure using **FREE TIER** services.

## Azure Free Account Benefits

With a new Azure account, you get:
- **$200 credit** for the first 30 days
- **12 months of free services** including:
  - 750 hours/month of Linux/Windows Virtual Machines
  - 5 GB of Azure Files
  - 5 GB of LRS Blob storage
  - 100,000 requests/month to Azure Functions
  - **Free PostgreSQL Database (B1bs tier) for 12 months**

## Free Tier Architecture

This configuration uses only free or nearly-free services:

| Service | Tier | Cost | Notes |
|---------|------|------|-------|
| Azure App Service (Linux) | F1 Free | **$0** | 1 GB storage, 60 CPU minutes/day |
| Azure Static Web Apps | Free | **$0** | Unlimited static sites, 100 GB bandwidth/month |
| Azure Database for PostgreSQL | B1bs Burstable | **$0 (12 months)** | Then ~$15/month |
| Azure Container Registry | Basic | **~$5/month** | Required for pipeline image storage |

**Total Cost: ~$5/month for first 12 months, then ~$20/month after**

## Limitations of Free Tier

- **App Service F1**: 60 CPU minutes per day (may sleep when inactive)
- **PostgreSQL B1bs**: Auto-pauses after 10 minutes of inactivity
- **No dedicated resources**: Shared infrastructure
- **No SLA**: No service level agreement
- **Limited scaling**: Cannot scale beyond free tier limits

## Prerequisites

1. **Create Azure Free Account**: https://azure.microsoft.com/free/
2. **Azure CLI installed and configured**
3. **Terraform 1.0+ installed**
4. **Docker installed** (for local testing only)

## Deployment Steps

### Option A: Deploy with Azure DevOps Pipeline (Recommended)

The pipeline automatically builds Docker images and deploys to Azure. See `docs/AZURE_DEVOPS_SETUP.md` for setup instructions.

### Option B: Manual Deployment

#### 1. Configure Terraform

Navigate to terraform directory:

```bash
cd terraform
```

#### 2. Set Up Variables

Copy the free-tier variables file:

```bash
cp azure-free-tier.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
- `db_username`: Database admin username
- `db_password`: Strong password for database
- `secret_key`: JWT secret key

#### 3. Initialize Terraform

```bash
terraform init -upgrade
```

#### 4. Plan the Deployment

```bash
terraform plan -var-file="terraform.tfvars"
```

#### 5. Apply the Configuration

```bash
terraform apply -var-file="terraform.tfvars"
```

#### 6. Build and Push Docker Images to ACR

After Terraform completes, build and push images to Azure Container Registry:

```bash
# Get ACR login server
ACR_LOGIN_SERVER=$(terraform output -raw container_registry_url)

# Build backend image
cd ../backend
docker build -t ${ACR_LOGIN_SERVER}/foodhawk-backend:latest .

# Login to ACR
az acr login --name $(echo $ACR_LOGIN_SERVER | cut -d. -f1)

# Push to ACR
docker push ${ACR_LOGIN_SERVER}/foodhawk-backend:latest
```

### 7. Deploy Frontend to Static Web Apps

The Terraform creates the Static Web App resource, but you need to deploy the frontend code manually or via GitHub Actions:

**Option A: Manual Deployment via Azure CLI**

```bash
# Install the Static Web Apps CLI
npm install -g @azure/static-web-apps-cli

# Deploy frontend
cd frontend
swa deploy --app-location . --output-location build
```

**Option B: GitHub Actions (Recommended)**

1. Push your code to GitHub
2. In Azure Portal, go to your Static Web App
3. Click "GitHub Actions" to set up automatic deployment
4. Authorize GitHub and select your repository
5. The workflow will be created automatically

### 8. Access Your Application

Get the URLs:

```bash
echo "Frontend URL: https://$(terraform output -raw frontend_url)"
echo "Backend URL: https://$(terraform output -raw backend_url)"
```

## Important Notes for Free Tier

### Cold Starts

Because the free tier uses auto-pause and sleep modes:
- **Backend**: May take 30-60 seconds to wake up after inactivity
- **Database**: Auto-pauses after 10 minutes, takes 20-30 seconds to resume
- **Frontend**: Static Web Apps has no cold start issues

### Monitoring Usage

Check your free tier usage:

```bash
# Check App Service usage
az monitor metrics list \
  --resource $(az resource show -g $(terraform output -raw resource_group_name) -n $(terraform output -raw backend_url | cut -d. -f1) --resource-type "Microsoft.Web/sites" --query id -o tsv) \
  --metric "CpuTime"

# Check Database usage
az postgres flexible-server show \
  --name $(terraform output -raw database_hostname | cut -d. -f1) \
  --resource-group $(terraform output -raw resource_group_name)
```

### Staying Within Free Limits

- The backend will automatically sleep when not in use
- Set `always_on = false` in the Terraform configuration (already done)
- Monitor your usage in Azure Portal: Cost Management + Billing

## Troubleshooting

### Backend Returns 503 Service Unavailable

This is normal for free tier - the app is sleeping. Wait 30-60 seconds and try again.

### Database Connection Timeout

The database is auto-paused. Wait 20-30 seconds for it to resume.

### Frontend Not Loading

Check the GitHub Actions workflow or manual deployment status.

## Upgrading from Free Tier

When you're ready to move beyond free tier:

1. **App Service**: Change `sku_name` from `F1` to `B1` (~$14/month) or higher
2. **Database**: Change `sku_name` from `B_Standard_B1bs` to higher tier
3. **Add Azure Container Registry**: For better image management

Modify the Terraform configuration and run `terraform apply`.

## Cost Comparison

| Tier | Monthly Cost | CPU | Storage | Best For |
|------|--------------|-----|---------|----------|
| Free (F1) | $0 | 60 min/day | 1 GB | Development, demos |
| Basic (B1) | ~$14 | Unlimited | 10 GB | Small production |
| Standard (S1) | ~$74 | Unlimited | 50 GB | Medium production |

## Alternative: Completely Free Options

If you want to avoid any costs even after 12 months:

1. **Render.com**: Free tier for web services
2. **Railway.app**: $5 free credit/month
3. **Fly.io**: Free allowance for small apps
4. **Vercel**: Free for frontend, paid for backend
5. **Heroku**: Free tier discontinued (paid only)

See the main README for alternative deployment options.

## Next Steps

- Monitor your free tier usage regularly
- Set up alerts before hitting limits
- Plan to upgrade before the 12-month free period ends
- Consider using Azure DevOps for CI/CD (free for open source)

## Security Considerations

Even on free tier:
- Use strong passwords for database
- Store secrets in Azure Key Vault when possible
- Enable HTTPS (automatic on Static Web Apps)
- Use environment variables for sensitive data
