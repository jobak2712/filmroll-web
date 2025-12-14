-- FilmRoll Database Schema
-- Run this migration in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    display_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- EVENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    host_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    event_date TIMESTAMPTZ NOT NULL,
    shot_limit_per_guest INTEGER NOT NULL DEFAULT 12,
    participant_cap INTEGER NOT NULL DEFAULT 25,
    reveal_mode TEXT NOT NULL DEFAULT 'instant' CHECK (reveal_mode IN ('instant', 'delayed')),
    reveal_time TIMESTAMPTZ,
    cover_image_url TEXT,
    join_code TEXT UNIQUE NOT NULL,
    is_locked BOOLEAN DEFAULT FALSE,
    allow_new_photos BOOLEAN DEFAULT TRUE,
    is_revealed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for join_code lookups
CREATE INDEX idx_events_join_code ON events(join_code);
CREATE INDEX idx_events_host_id ON events(host_id);

-- ============================================
-- PARTICIPANTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    guest_name TEXT,
    shots_taken INTEGER DEFAULT 0,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure unique participation per event
    UNIQUE(event_id, user_id)
);

CREATE INDEX idx_participants_event_id ON participants(event_id);

-- ============================================
-- PHOTOS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS photos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    participant_id UUID NOT NULL REFERENCES participants(id) ON DELETE CASCADE,
    storage_path TEXT NOT NULL,
    thumbnail_path TEXT,
    file_size BIGINT NOT NULL DEFAULT 0,
    captured_at TIMESTAMPTZ DEFAULT NOW(),
    uploaded_at TIMESTAMPTZ,
    is_uploaded BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_photos_event_id ON photos(event_id);
CREATE INDEX idx_photos_participant_id ON photos(participant_id);

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function to generate unique join code
CREATE OR REPLACE FUNCTION generate_join_code()
RETURNS TEXT AS $$
DECLARE
    chars TEXT := 'abcdefghijklmnopqrstuvwxyz0123456789';
    result TEXT := '';
    i INTEGER;
BEGIN
    FOR i IN 1..6 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate join code
CREATE OR REPLACE FUNCTION set_join_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.join_code IS NULL THEN
        NEW.join_code := generate_join_code();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_join_code
    BEFORE INSERT ON events
    FOR EACH ROW
    EXECUTE FUNCTION set_join_code();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trigger_events_updated_at
    BEFORE UPDATE ON events
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Function to auto-reveal events at scheduled time
CREATE OR REPLACE FUNCTION check_and_reveal_events()
RETURNS void AS $$
BEGIN
    UPDATE events
    SET is_revealed = TRUE
    WHERE reveal_mode = 'delayed'
      AND reveal_time IS NOT NULL
      AND reveal_time <= NOW()
      AND is_revealed = FALSE;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE photos ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can view own profile"
    ON users FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (auth.uid() = id);

-- Events policies
CREATE POLICY "Hosts can view own events"
    ON events FOR SELECT
    USING (auth.uid() = host_id);

CREATE POLICY "Anyone can view events by join code"
    ON events FOR SELECT
    USING (TRUE);

CREATE POLICY "Hosts can create events"
    ON events FOR INSERT
    WITH CHECK (auth.uid() = host_id);

CREATE POLICY "Hosts can update own events"
    ON events FOR UPDATE
    USING (auth.uid() = host_id);

CREATE POLICY "Hosts can delete own events"
    ON events FOR DELETE
    USING (auth.uid() = host_id);

-- Participants policies
CREATE POLICY "Anyone can view participants of an event"
    ON participants FOR SELECT
    USING (TRUE);

CREATE POLICY "Anyone can join an event"
    ON participants FOR INSERT
    WITH CHECK (TRUE);

CREATE POLICY "Participants can update own record"
    ON participants FOR UPDATE
    USING (user_id = auth.uid() OR user_id IS NULL);

-- Photos policies
CREATE POLICY "Hosts can view all photos in their events"
    ON photos FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM events
            WHERE events.id = photos.event_id
            AND events.host_id = auth.uid()
        )
    );

CREATE POLICY "Participants can view photos after reveal"
    ON photos FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM events
            WHERE events.id = photos.event_id
            AND (events.is_revealed = TRUE OR events.reveal_mode = 'instant')
        )
    );

CREATE POLICY "Participants can insert photos"
    ON photos FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM participants
            WHERE participants.id = photos.participant_id
        )
    );

CREATE POLICY "Hosts can delete photos"
    ON photos FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM events
            WHERE events.id = photos.event_id
            AND events.host_id = auth.uid()
        )
    );

-- ============================================
-- STORAGE BUCKET
-- ============================================
-- Run this in Supabase Dashboard > Storage

-- Create bucket for photos
-- INSERT INTO storage.buckets (id, name, public)
-- VALUES ('photos', 'photos', false);

-- Storage policies (run in SQL editor)
-- CREATE POLICY "Anyone can upload photos"
--     ON storage.objects FOR INSERT
--     WITH CHECK (bucket_id = 'photos');

-- CREATE POLICY "Authenticated users can view photos"
--     ON storage.objects FOR SELECT
--     USING (bucket_id = 'photos');
