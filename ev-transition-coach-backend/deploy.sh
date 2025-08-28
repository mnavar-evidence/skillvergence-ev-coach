#!/bin/bash

echo "🚂 Railway Deployment Script for EV Coach Backend"
echo "================================================"

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI not found. Installing..."
    npm install -g @railway/cli
fi

# Check if logged in (this will prompt if not)
echo "🔐 Checking Railway login status..."
railway whoami || railway login

# Initialize project if not already done
if [ ! -f "railway.toml" ]; then
    echo "🎯 Initializing Railway project..."
    railway init
else
    echo "✅ Railway project already initialized"
fi

# Add PostgreSQL if not already added
echo "🐘 Ensuring PostgreSQL is available..."
railway add postgresql || echo "PostgreSQL may already be added"

echo "🔧 Setting environment variables..."
echo "Please set your OPENAI_API_KEY manually with:"
echo "railway variables set OPENAI_API_KEY=your-key-here"
echo ""

# Set other environment variables
railway variables set NODE_ENV=production
railway variables set PORT=3000
railway variables set CORS_ORIGIN="https://ev-coach.railway.app"
railway variables set LOG_LEVEL=info
railway variables set ANALYTICS_ENABLED=true
railway variables set RATE_LIMIT_WINDOW_MS=900000
railway variables set RATE_LIMIT_MAX_REQUESTS=100
railway variables set MAX_FILE_SIZE=5mb

# Generate and set JWT secret
JWT_SECRET=$(openssl rand -hex 32)
railway variables set JWT_SECRET="$JWT_SECRET"
echo "✅ Generated and set JWT_SECRET"

echo "🚀 Deploying to Railway..."
railway up

echo "🌐 Getting deployment URL..."
railway domain

echo ""
echo "✅ Deployment complete!"
echo "📱 Update your iOS app Config.swift with the production URL shown above"
echo "🔑 Don't forget to set your OPENAI_API_KEY: railway variables set OPENAI_API_KEY=your-key-here"