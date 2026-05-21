# Supabase Setup for FoodHawk Platform

This guide explains how to set up Supabase as your free PostgreSQL database for the FoodHawk Platform.

## Why Supabase?

- **Free tier**: 500MB database storage
- **No Azure subscription limits**: Works with any Azure subscription
- **Fully managed**: No database administration needed
- **PostgreSQL compatible**: Works with your existing FastAPI/SQLAlchemy setup

## Step 1: Create Supabase Account

1. Go to https://supabase.com/
2. Click "Start your project"
3. Sign up with GitHub or email
4. Verify your email address

## Step 2: Create a New Project

1. Click "New Project"
2. Organization: Your organization (or create one)
3. Name: `foodhawk`
4. Database Password: Generate a strong password (save this!)
5. Region: Choose a region close to your Azure region (e.g., East US)
6. Click "Create new project"

Wait for the project to be created (usually 1-2 minutes).

## Step 3: Get Database Connection URL

1. In your Supabase project, go to **Settings** → **Database**
2. Scroll down to **Connection string**
3. Copy the **URI** format
4. Replace `[YOUR-PASSWORD]` with your actual database password

Example:
```
postgresql://postgres.abc123:yourpassword@aws-0-us-east-1.pooler.supabase.com:5432/postgres
```

## Step 4: Create Database Table

Run this SQL in Supabase SQL Editor:

```sql
-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    is_vendor BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create products table
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    vendor_id INTEGER REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    original_price DECIMAL(10,2) NOT NULL,
    current_price DECIMAL(10,2) NOT NULL,
    expiry_date TIMESTAMP NOT NULL,
    quantity INTEGER NOT NULL,
    image_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES users(id),
    vendor_id INTEGER REFERENCES users(id),
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Step 5: Update Azure DevOps Pipeline Variables

In your Azure DevOps pipeline, update the variables:

| Variable | Value | Secret |
|----------|-------|--------|
| azureSubscription | azureSubscription | No |
| azureRegion | eastus | No |
| projectName | foodhawk | No |
| environment | production | No |
| supabaseDatabaseUrl | Your Supabase connection URL | Yes |
| secretKey | Your JWT secret key | Yes |

**Remove these old variables:**
- dbUsername
- dbPassword

## Step 6: Commit and Deploy

```bash
git add .
git commit -m "Switch to Supabase database"
git push
```

Then run the pipeline in Azure DevOps.

## Cost

- **Supabase Free Tier**: $0 (500MB database)
- **Azure Container Registry**: ~$5/month
- **Azure App Service F1**: $0
- **Azure Static Web Apps**: $0

**Total: ~$5/month**

## Troubleshooting

### Connection Issues

- Ensure your Supabase project is active (not paused)
- Check that the connection URL is correct
- Verify the password matches what you set in Supabase

### Table Not Found

- Run the SQL commands in Step 4 to create tables
- Check the SQL Editor in Supabase dashboard

### Performance Issues

- Free tier has connection limits
- Consider upgrading if you need more performance
