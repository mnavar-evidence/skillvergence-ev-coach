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

# Link to existing project or create new one
echo "🔗 Linking to Railway project..."
if [ ! -f ".railway" ]; then
    echo "No project linked. Please run 'railway link' manually to connect to your project"
    echo "Or create a new project with 'railway init'"
    read -p "Press Enter after you've linked your project..."
fi

# Add PostgreSQL database
echo "🐘 Adding PostgreSQL database..."
railway add --database postgres || echo "PostgreSQL may already be added"

echo "🔧 Setting environment variables..."
echo "Please set your OPENAI_API_KEY manually after this script:"
echo "railway variables --set 'OPENAI_API_KEY=your-key-here'"
echo ""

# Set environment variables using correct syntax
echo "Setting NODE_ENV..."
railway variables --set "NODE_ENV=production" || echo "Failed to set NODE_ENV"

echo "Setting PORT..."
railway variables --set "PORT=3000" || echo "Failed to set PORT"

echo "Setting CORS_ORIGIN..."
railway variables --set "CORS_ORIGIN=https://ev-coach.railway.app" || echo "Failed to set CORS_ORIGIN"

echo "Setting LOG_LEVEL..."
railway variables --set "LOG_LEVEL=info" || echo "Failed to set LOG_LEVEL"

echo "Setting ANALYTICS_ENABLED..."
railway variables --set "ANALYTICS_ENABLED=true" || echo "Failed to set ANALYTICS_ENABLED"

echo "Setting RATE_LIMIT_WINDOW_MS..."
railway variables --set "RATE_LIMIT_WINDOW_MS=900000" || echo "Failed to set RATE_LIMIT_WINDOW_MS"

echo "Setting RATE_LIMIT_MAX_REQUESTS..."
railway variables --set "RATE_LIMIT_MAX_REQUESTS=100" || echo "Failed to set RATE_LIMIT_MAX_REQUESTS"

echo "Setting MAX_FILE_SIZE..."
railway variables --set "MAX_FILE_SIZE=5mb" || echo "Failed to set MAX_FILE_SIZE"

# Generate and set JWT secret
JWT_SECRET=$(openssl rand -hex 32)
echo "Setting JWT_SECRET..."
railway variables --set "JWT_SECRET=$JWT_SECRET" || echo "Failed to set JWT_SECRET"
echo "✅ Generated and set JWT_SECRET"

echo ""
echo "🚀 Deploying to Railway..."
railway up

echo ""
echo "🌐 Getting deployment URL..."
railway domain || railway status

echo ""
echo "✅ Deployment complete!"
echo "📱 Update your iOS app Config.swift with the production URL shown above"
echo "🔑 Don't forget to set your OPENAI_API_KEY manually:"
echo "   railway variables --set 'OPENAI_API_KEY=your-actual-key-here'"