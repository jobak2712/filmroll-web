#!/bin/bash

# FilmRoll Supabase Setup Script
# Run this after creating your Supabase project

set -e

echo "🎬 FilmRoll Backend Setup"
echo "========================="
echo ""

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found. Installing..."
    npm install -g supabase
fi

echo "✅ Supabase CLI found"

# Check if logged in
echo ""
echo "📝 Checking Supabase login status..."
if ! supabase projects list &> /dev/null; then
    echo "Please login to Supabase:"
    supabase login
fi

echo "✅ Logged in to Supabase"

# Get project reference
echo ""
echo "📋 Enter your Supabase project reference (from project settings):"
read -p "Project Ref: " PROJECT_REF

if [ -z "$PROJECT_REF" ]; then
    echo "❌ Project reference is required"
    exit 1
fi

# Link project
echo ""
echo "🔗 Linking to project..."
supabase link --project-ref "$PROJECT_REF"

echo "✅ Project linked"

# Deploy functions
echo ""
echo "🚀 Deploying Edge Functions..."

FUNCTIONS=(
    "createEvent"
    "joinEvent"
    "signPhotoUpload"
    "registerPhoto"
    "revealEvent"
    "getEventPhotos"
    "createMessage"
    "addReaction"
)

for func in "${FUNCTIONS[@]}"; do
    echo "  Deploying $func..."
    supabase functions deploy "$func" --no-verify-jwt
done

echo "✅ All functions deployed"

# Prompt for service role key
echo ""
echo "🔐 Setting up secrets..."
echo "Enter your service_role key (from Supabase Dashboard > Settings > API):"
read -s SERVICE_ROLE_KEY

if [ -n "$SERVICE_ROLE_KEY" ]; then
    supabase secrets set SUPABASE_SERVICE_ROLE_KEY="$SERVICE_ROLE_KEY"
    echo "✅ Service role key set"
else
    echo "⚠️  Skipped service role key (some functions may not work)"
fi

# Summary
echo ""
echo "================================"
echo "🎉 Setup Complete!"
echo "================================"
echo ""
echo "Next steps:"
echo "1. Run the SQL migrations in Supabase Dashboard > SQL Editor"
echo "   - migrations/001_initial_schema.sql"
echo "   - migrations/002_add_features.sql"
echo ""
echo "2. Create storage bucket 'photos' in Storage section"
echo ""
echo "3. Update iOS app with your credentials:"
echo "   - Open FilmRoll/Services/SupabaseService.swift"
echo "   - Set baseUrl and anonKey"
echo "   - Set useMockData = false in AuthViewModel.swift"
echo ""
echo "4. Configure auth providers (Apple, Google) in Authentication > Providers"
echo ""
echo "Your project URL: https://$PROJECT_REF.supabase.co"
echo ""
