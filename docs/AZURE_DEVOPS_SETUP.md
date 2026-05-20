# Azure DevOps Pipeline Setup Guide

This guide explains how to set up Azure DevOps pipeline to deploy your FoodHawk Platform to Azure.

## Prerequisites

1. **Azure DevOps Account**: https://dev.azure.com/
2. **Azure Repository**: Your code should be in Azure Repos
3. **Azure Subscription**: With free tier services enabled

## Step 1: Create Azure DevOps Project

1. Go to https://dev.azure.com/
2. Click "Create project"
3. Project name: `foodhawk-platform`
4. Visibility: Private
5. Click "Create"

## Step 2: Import Your Code

If your code is not already in Azure Repos:

1. In your project, click "Repos"
2. Click "Import"
3. Choose "Git"
4. Enter your repository URL (from GitHub or local)
5. Click "Import"

Or push your local code:

```bash
# From your local project directory
git remote add origin https://dev.azure.com/YOUR_ORG/YOUR_PROJECT/_git/foodhawk-platform
git push -u origin --all
```

## Step 3: Create Service Connection

### Azure Service Connection

1. In Azure DevOps, go to **Project Settings** → **Service connections**
2. Click **New service connection**
3. Select **Azure Resource Manager**
4. Choose **Service principal (automatic)**
5. Select your subscription
6. Resource group: (will be created by Terraform)
7. Service connection name: `azureSubscription`
8. Grant access to all pipelines: **Checked**
9. Click **Create**

## Step 4: Configure Pipeline Variables

### Option A: Using Pipeline Variables (Recommended)

1. Go to **Pipelines** → **Create Pipeline**
2. Select your repository (Azure Repos Git)
3. Choose **Existing Azure Pipelines YAML file**
4. Select branch: `main`
5. Path: `/azure-pipelines.yml`
6. Click **Continue**

Then add variables:

1. Click **Variables** tab
2. Add the following variables:

| Variable Name | Value | Secret |
|---------------|-------|--------|
| `azureSubscription` | azureSubscription | No |
| `azureRegion` | eastus | No |
| `projectName` | foodhawk | No |
| `environment` | production | No |
| `dbUsername` | foodhawkadmin | Yes |
| `dbPassword` | Your secure password | Yes |
| `secretKey` | Your JWT secret key | Yes |

### Option B: Using Variable Groups

1. Go to **Pipelines** → **Library**
2. Click **+ Variable group**
3. Name: `foodhawk-variables`
4. Add variables as above
5. Save

Then in your pipeline YAML, reference the group:

```yaml
variables:
- group: foodhawk-variables
```

## Step 5: Create the Pipeline

### Using Terraform Pipeline (Recommended)

1. Copy `azure-pipelines.yml` to your repository root
2. In Azure DevOps, create a new pipeline
3. Select your repository
4. Choose the YAML file
5. Configure variables as described above
6. Save and run

### Using Classic Pipeline (Simpler)

1. Copy `azure-pipelines-classic.yml` to your repository root
2. Create pipeline using this file
3. Configure service connections
4. Add variable: `staticWebAppsToken` (get from Azure Portal)

## Step 6: Run the Pipeline

1. Click **Run** on the pipeline
2. Select branch: `main`
3. Click **Run**

The pipeline will:
1. Build Docker images
2. Push to Docker Hub
3. Apply Terraform configuration
4. Deploy to Azure App Service and Static Web Apps

## Step 7: Configure Frontend Deployment

For Static Web Apps, you need to set up GitHub Actions or manual deployment:

### Option A: GitHub Actions (if code is also on GitHub)

1. Go to Azure Portal
2. Navigate to your Static Web App
3. Click "GitHub Actions"
4. Authorize GitHub
5. Select your repository
6. The workflow file will be created automatically

### Option B: Manual Deployment

After the pipeline creates the Static Web App resource:

```bash
# Install Static Web Apps CLI
npm install -g @azure/static-web-apps-cli

# Deploy frontend
cd frontend
swa deploy --app-location . --output-location build
```

## Step 8: Access Your Application

After pipeline completes:

1. Go to the pipeline run summary
2. Check the "Get Deployment URLs" step output
3. Access your application at the shown URLs

Or get URLs manually:

```bash
# Via Azure CLI
az webapp show --name foodhawk-backend --resource-group foodhawk-production-rg --query defaultHostName -o tsv
az staticwebapp show --name foodhawk-frontend --resource-group foodhawk-production-rg --query defaultHostname -o tsv
```

## Pipeline Stages Explained

### Build Stage
- Builds Docker image for backend from source code
- Pushes to Azure Container Registry (ACR)
- Tags with build ID and `latest`

### Deploy Stage
- Initializes Terraform
- Applies Azure infrastructure (creates ACR, database, app services)
- Deploys backend to App Service using ACR image
- Deploys frontend to Static Web Apps

## Troubleshooting

### Terraform Apply Fails

- Check Azure service connection has correct permissions
- Verify variables are set correctly
- Check Azure subscription is active

### App Service Deployment Fails

- Ensure Docker image exists in Azure Container Registry
- Check ACR name matches what Terraform created
- Verify App Service plan is created

### Static Web Apps Deployment Fails

- Verify staticWebAppsToken is set
- Check frontend build succeeds locally
- Ensure GitHub Actions workflow is configured

## Security Best Practices

1. **Use Azure Key Vault**: Store secrets in Key Vault instead of pipeline variables
2. **Managed Identity**: Use managed identities instead of service principals
3. **Branch Policies**: Require pull requests before merging to main
4. **Environment Approvals**: Require manual approval for production deployments

## Adding Azure Key Vault Integration

1. Create Key Vault in Azure
2. Add secrets: dbPassword, secretKey
3. Create Azure service connection with Key Vault access
4. Add to pipeline:

```yaml
- task: AzureKeyVault@1
  inputs:
    azureSubscription: '$(azureSubscription)'
    KeyVaultName: 'foodhawk-kv'
    SecretsFilter: '*'
    RunAsPreJob: false
```

## Monitoring Pipeline Runs

1. Go to **Pipelines** in Azure DevOps
2. Click on your pipeline
3. View run history and logs
4. Set up notifications for failed runs

## Next Steps

- Add automated tests to pipeline
- Set up staging environment
- Configure automatic rollback on failure
- Add performance monitoring
- Set up alerting
