# Render Deployment Guide for FoodHawk Platform

This guide explains how to deploy the FoodHawk Platform to Render.com using free tiers.

## Why Render?

- **Free tiers available**: Web Services, PostgreSQL, Static Sites
- **Automatic deployments**: Connects to GitHub for CI/CD
- **No region restrictions**: Works with any account
- **Simple configuration**: Single render.yaml file
- **Fully managed**: No infrastructure management needed

## Prerequisites

1. Render account (free at https://render.com/)
2. GitHub account
3. Your FoodHawk code pushed to GitHub

## Step 1: Create Render Account

1. Go to https://render.com/
2. Click "Sign Up"
3. Sign up with GitHub
4. Authorize Render to access your GitHub repositories

## Step 2: Push Code to GitHub

```bash
git add .
git commit -m "Add Render configuration"
git push origin main
```

## Step 3: Deploy to Render

### Option A: Using render.yaml (Recommended)

1. In Render dashboard, click "New"
2. Click "Blueprint" (or "New Blueprint Instance")
3. Select your GitHub repository: `food-hawk-platform`
4. Select the branch: `main`
5. Render will automatically detect `render.yaml`
6. Click "Apply" to deploy

### Option B: Manual Setup

#### Deploy PostgreSQL Database

1. Click "New" → "PostgreSQL"
2. Name: `foodhawk-db`
3. Database: `foodhawk`
4. User: `foodhawk`
5. Region: Oregon (or closest to you)
6. Plan: Free
7. Click "Create Database"
8. Copy the connection string from the dashboard

#### Deploy Backend

1. Click "New" → "Web Service"
2. Connect your GitHub repository
3. Name: `foodhawk-backend`
4. Environment: Docker
5. Docker Context: `./backend`
6. Dockerfile Path: `./backend/Dockerfile`
7. Region: Oregon
8. Plan: Free
9. Add Environment Variables:
   - `DATABASE_URL`: (paste your PostgreSQL connection string)
   - `SECRET_KEY`: (generate a secure random string)
   - `JWT_ALGORITHM`: `HS256`
   - `ACCESS_TOKEN_EXPIRE_MINUTES`: `1440`
10. Click "Create Web Service"

#### Deploy Frontend

1. Click "New" → "Web Service"
2. Connect your GitHub repository
3. Name: `foodhawk-frontend`
4. Environment: Docker
5. Docker Context: `./frontend`
6. Dockerfile Path: `./frontend/Dockerfile`
7. Region: Oregon
8. Plan: Free
9. Add Environment Variables:
   - `VITE_API_URL`: (use backend service URL, e.g., `https://foodhawk-backend.onrender.com`)
10. Click "Create Web Service"

## Step 4: Create Database Tables

After the database is created, you need to create the tables:

1. Go to your PostgreSQL service in Render
2. Click "Shell" or "Connect" to access the database
3. Run the following SQL commands:

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

## Step 5: Access Your Application

After deployment completes:

- **Backend URL**: `https://foodhawk-backend.onrender.com`
- **Frontend URL**: `https://foodhawk-frontend.onrender.com`
- **API Endpoints**: Backend API is available at the backend URL

## Cost

- **Backend Web Service**: Free (up to 750 hours/month)
- **Frontend Web Service**: Free (up to 750 hours/month)
- **PostgreSQL Database**: Free (90 days, then $7/month)
- **Total**: $0 (first 90 days), then $7/month

## Automatic Deployments

Render automatically deploys when you push to GitHub:
- Push to `main` branch → Automatic deployment
- Pull requests → Preview deployments
- Environment variables configured in Render dashboard

## Troubleshooting

### Build Fails

- Check Dockerfile paths are correct
- Verify Docker context is set to `./backend` or `./frontend`
- Check build logs in Render dashboard

### Database Connection Error

- Verify DATABASE_URL environment variable is correct
- Check database is running in Render dashboard
- Ensure tables are created

### Frontend Can't Connect to Backend

- Update VITE_API_URL in frontend environment variables
- Use the backend service URL from Render dashboard
- Check CORS settings in backend

### Service Sleeps (Free Tier)

Free tier services sleep after 15 minutes of inactivity. First request may take ~30 seconds to wake up. Upgrade to paid plan to keep services always on.

## Monitoring

Render provides:
- Real-time logs
- Metrics dashboard
- Error tracking
- Deployment history

Access these from the service dashboard in Render.

## Scaling

To scale beyond free tier:
1. Go to service settings
2. Change plan to Starter ($7/month) or Standard ($25/month)
3. Adjust resources as needed

## Security Best Practices

- Keep SECRET_KEY secure (use Render's generated values)
- Use environment variables for all sensitive data
- Enable Render's automatic SSL
- Regularly update dependencies
- Monitor logs for suspicious activity
