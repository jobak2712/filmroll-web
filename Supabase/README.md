# FilmRoll Supabase Backend

Complete backend setup guide for the FilmRoll iOS app.

## Quick Start

### Prerequisites
- [Supabase CLI](https://supabase.com/docs/guides/cli) installed
- A Supabase account at [supabase.com](https://supabase.com)
- Node.js 18+ (for local development)

### 1. Create Supabase Project

1. Go to [supabase.com/dashboard](https://supabase.com/dashboard)
2. Click "New Project"
3. Fill in:
   - **Name:** FilmRoll
   - **Database Password:** (save this securely)
   - **Region:** Choose closest to your users
4. Wait for project to be created (~2 minutes)
5. Note your credentials from Settings > API:
   - `Project URL` (e.g., `https://xxxxx.supabase.co`)
   - `anon public` key
   - `service_role` key (keep secret!)

### 2. Run Database Migration

1. Go to **SQL Editor** in Supabase Dashboard
2. Click "New Query"
3. Copy the entire contents of `migrations/001_initial_schema.sql`
4. Click "Run" (or Cmd+Enter)
5. Verify tables were created in **Table Editor**

### 3. Create Storage Bucket

1. Go to **Storage** in Supabase Dashboard
2. Click "New Bucket"
3. Configure:
   - **Name:** `photos`
   - **Public bucket:** OFF (private)
   - **File size limit:** 10MB
   - **Allowed MIME types:** `image/jpeg, image/png, image/heic`
4. Click "Create bucket"

5. Add storage policies - go to **Storage > Policies** and add:

```sql
-- Allow anyone to upload photos (guests don't have auth)
CREATE POLICY "Allow photo uploads"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'photos');

-- Allow anyone to read photos (access controlled by app logic)
CREATE POLICY "Allow photo reads"
ON storage.objects FOR SELECT
USING (bucket_id = 'photos');

-- Allow deletion by authenticated users
CREATE POLICY "Allow photo deletion"
ON storage.objects FOR DELETE
USING (bucket_id = 'photos' AND auth.role() = 'authenticated');
```

### 4. Enable Authentication Providers

1. Go to **Authentication > Providers**
2. Enable **Email** (already enabled by default)
3. Enable **Apple**:
   - Add your Apple Services ID
   - Add your Apple Team ID
   - Upload your Apple Private Key
4. Enable **Google**:
   - Add your Google Client ID
   - Add your Google Client Secret

### 5. Deploy Edge Functions

```bash
# Navigate to Supabase folder
cd FilmRoll/Supabase

# Login to Supabase CLI
supabase login

# Link to your project (get ref from project settings)
supabase link --project-ref YOUR_PROJECT_REF

# Deploy all functions
supabase functions deploy createEvent
supabase functions deploy joinEvent
supabase functions deploy signPhotoUpload
supabase functions deploy registerPhoto
supabase functions deploy revealEvent
supabase functions deploy getEventPhotos
supabase functions deploy joinPage
supabase functions deploy webUpload
supabase functions deploy slideshow

# Verify deployment
supabase functions list
```

### 6. Set Function Secrets

```bash
# Set the service role key for functions that need elevated access
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### 7. Configure iOS App

Update `FilmRoll/Services/SupabaseService.swift`:

```swift
private let baseUrl = "https://YOUR_PROJECT_REF.supabase.co"
private let anonKey = "YOUR_ANON_KEY"
```

Then set `useMockData = false` in `AuthViewModel.swift`:

```swift
@Published var useMockData = false // Enable real Supabase
```

---

## API Reference

### Authentication

All authenticated endpoints require the `Authorization` header:
```
Authorization: Bearer <access_token>
```

### Endpoints

#### POST `/functions/v1/createEvent`
Create a new event (requires auth).

**Request:**
```json
{
  "title": "Sarah's Birthday",
  "description": "30th birthday celebration",
  "event_date": "2024-12-25T20:00:00Z",
  "shot_limit_per_guest": 24,
  "participant_cap": 50,
  "reveal_mode": "delayed",
  "reveal_time": "2024-12-26T00:00:00Z"
}
```

**Response:**
```json
{
  "event": {
    "id": "uuid",
    "join_code": "abc123",
    "title": "Sarah's Birthday",
    ...
  }
}
```

#### POST `/functions/v1/joinEvent`
Join an event as a guest (no auth required).

**Request:**
```json
{
  "join_code": "abc123",
  "guest_name": "John Doe"
}
```

**Response:**
```json
{
  "participant": {
    "id": "uuid",
    "event_id": "uuid",
    "guest_name": "John Doe",
    "shots_taken": 0
  },
  "event": {
    "id": "uuid",
    "title": "Sarah's Birthday",
    "shot_limit_per_guest": 24,
    ...
  }
}
```

#### POST `/functions/v1/signPhotoUpload`
Get a signed URL for photo upload.

**Request:**
```json
{
  "event_id": "uuid",
  "participant_id": "uuid",
  "file_name": "photo.jpg",
  "content_type": "image/jpeg"
}
```

**Response:**
```json
{
  "signed_url": "https://...",
  "storage_path": "event_id/participant_id/timestamp_photo.jpg",
  "token": "upload_token"
}
```

#### POST `/functions/v1/registerPhoto`
Register a photo after upload.

**Request:**
```json
{
  "event_id": "uuid",
  "participant_id": "uuid",
  "storage_path": "event_id/participant_id/timestamp_photo.jpg",
  "file_size": 1234567
}
```

**Response:**
```json
{
  "photo": { ... },
  "shots_taken": 5,
  "shots_remaining": 19
}
```

#### POST `/functions/v1/revealEvent`
Reveal event photos (host only, requires auth).

**Request:**
```json
{
  "event_id": "uuid"
}
```

#### GET `/functions/v1/getEventPhotos`
Get photos for an event.

**Query Params:**
- `event_id` (required)
- `participant_id` (optional)
- `is_host` (optional, "true"/"false")

**Response:**
```json
{
  "photos": [
    {
      "id": "uuid",
      "url": "https://signed-url...",
      "captured_at": "2024-12-25T20:30:00Z",
      "participants": { "guest_name": "John" }
    }
  ],
  "total_count": 42
}
```

---

## Database Schema

### Tables

| Table | Description |
|-------|-------------|
| `users` | Host accounts (synced with Supabase Auth) |
| `events` | Event/film metadata |
| `participants` | Guest records for each event |
| `photos` | Photo metadata and storage paths |

### Key Features

- **Auto-generated join codes:** 6-character alphanumeric codes
- **Row Level Security (RLS):** Enabled on all tables
- **Automatic timestamps:** `created_at`, `updated_at` triggers
- **Scheduled reveals:** `check_and_reveal_events()` function

---

## Local Development

### Run Supabase Locally

```bash
# Start local Supabase
supabase start

# This gives you local URLs:
# API URL: http://localhost:54321
# Studio URL: http://localhost:54323
# Anon Key: eyJ...

# Run migrations locally
supabase db reset

# Serve functions locally
supabase functions serve
```

### Test Functions

```bash
# Test createEvent
curl -X POST http://localhost:54321/functions/v1/createEvent \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Event","event_date":"2024-12-25T20:00:00Z"}'

# Test joinEvent
curl -X POST http://localhost:54321/functions/v1/joinEvent \
  -H "Content-Type: application/json" \
  -d '{"join_code":"abc123","guest_name":"Test User"}'
```

---

## New Features (v2)

### Web Upload (No App Required)
Guests can upload photos directly from their browser without installing the app.

**URL:** `https://YOUR_PROJECT.supabase.co/functions/v1/webUpload/{join_code}`

Features:
- Mobile-optimized responsive design
- Camera capture or gallery selection
- Shot limit tracking per guest
- Works on any device with a browser

### Live Slideshow
Display photos on a TV/projector during the event.

**URL:** `https://YOUR_PROJECT.supabase.co/functions/v1/slideshow/{join_code}?interval=5`

Features:
- Auto-advances through photos
- Shows guest names and captions
- QR code overlay for guests to join
- "New photo" alerts when photos arrive
- Configurable interval (default 5 seconds)

### Join Page
Smart landing page that tries to open the app, or offers web upload.

**URL:** `https://YOUR_PROJECT.supabase.co/functions/v1/joinPage/{join_code}`

### Enhanced Features Migration
Run `migrations/004_enhanced_features.sql` to enable:
- Push notification tokens storage
- Scheduled notifications (auto-notify at reveal time)
- Video/voice message support
- Print ordering system
- Slideshow settings per event

---

## Production Checklist

- [ ] Database migration 001 applied (initial schema)
- [ ] Database migration 002 applied (features)
- [ ] Database migration 003 applied (storage policies)
- [ ] Database migration 004 applied (enhanced features)
- [ ] Storage bucket created with policies
- [ ] All edge functions deployed
- [ ] Service role key set as secret
- [ ] Apple Sign In configured
- [ ] Google Sign In configured
- [ ] iOS app credentials updated
- [ ] `useMockData` set to `false`
- [ ] Test full flow: create event → join → upload photo → reveal
- [ ] Test web upload flow
- [ ] Test slideshow display

---

## Troubleshooting

### "Event not found" error
- Check join code is lowercase
- Verify event exists in database

### Photo upload fails
- Check storage bucket exists
- Verify storage policies are set
- Check file size < 10MB

### Auth errors
- Verify anon key is correct
- Check Authorization header format
- Ensure user exists in auth.users

### Function deployment fails
- Run `supabase login` again
- Check project is linked: `supabase link`
- Verify Deno version compatibility
