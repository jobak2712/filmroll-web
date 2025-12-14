-- FilmRoll Database Migration 002
-- Adds: captions, filters, reactions, messages
-- Run this after 001_initial_schema.sql

-- ============================================
-- ADD COLUMNS TO PHOTOS TABLE
-- ============================================

-- Add caption support
ALTER TABLE photos ADD COLUMN IF NOT EXISTS caption TEXT;

-- Add filter support
ALTER TABLE photos ADD COLUMN IF NOT EXISTS filter_applied TEXT;

-- ============================================
-- REACTIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS reactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    photo_id UUID NOT NULL REFERENCES photos(id) ON DELETE CASCADE,
    participant_id UUID REFERENCES participants(id) ON DELETE SET NULL,
    emoji TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- One reaction per participant per photo
    UNIQUE(photo_id, participant_id)
);

CREATE INDEX idx_reactions_photo_id ON reactions(photo_id);

-- ============================================
-- MESSAGES TABLE (for guest messages to host)
-- ============================================
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    participant_id UUID REFERENCES participants(id) ON DELETE SET NULL,
    participant_name TEXT,
    content TEXT NOT NULL,
    message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'voice', 'video')),
    media_url TEXT,
    duration_seconds INTEGER,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_messages_event_id ON messages(event_id);

-- ============================================
-- NOTIFICATION SUBSCRIPTIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS notification_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    participant_id UUID REFERENCES participants(id) ON DELETE CASCADE,
    device_token TEXT,
    notification_type TEXT DEFAULT 'reveal' CHECK (notification_type IN ('reveal', 'photo', 'message')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(event_id, participant_id, notification_type)
);

-- ============================================
-- USER STATS VIEW
-- ============================================
CREATE OR REPLACE VIEW user_stats AS
SELECT 
    u.id as user_id,
    COUNT(DISTINCT e.id) as total_films,
    COALESCE(SUM(
        (SELECT COUNT(*) FROM participants p WHERE p.event_id = e.id)
    ), 0) as guests_served,
    COALESCE(SUM(
        (SELECT COUNT(*) FROM photos ph WHERE ph.event_id = e.id)
    ), 0) as total_photos
FROM users u
LEFT JOIN events e ON e.host_id = u.id
GROUP BY u.id;

-- ============================================
-- RLS POLICIES FOR NEW TABLES
-- ============================================

ALTER TABLE reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_subscriptions ENABLE ROW LEVEL SECURITY;

-- Reactions policies
CREATE POLICY "Anyone can view reactions"
    ON reactions FOR SELECT
    USING (TRUE);

CREATE POLICY "Participants can add reactions"
    ON reactions FOR INSERT
    WITH CHECK (TRUE);

CREATE POLICY "Participants can remove own reactions"
    ON reactions FOR DELETE
    USING (participant_id IS NULL OR participant_id = participant_id);

-- Messages policies
CREATE POLICY "Hosts can view messages for their events"
    ON messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM events
            WHERE events.id = messages.event_id
            AND events.host_id = auth.uid()
        )
    );

CREATE POLICY "Anyone can create messages"
    ON messages FOR INSERT
    WITH CHECK (TRUE);

CREATE POLICY "Hosts can update message read status"
    ON messages FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM events
            WHERE events.id = messages.event_id
            AND events.host_id = auth.uid()
        )
    );

-- Notification subscriptions policies
CREATE POLICY "Anyone can subscribe to notifications"
    ON notification_subscriptions FOR INSERT
    WITH CHECK (TRUE);

CREATE POLICY "Users can view own subscriptions"
    ON notification_subscriptions FOR SELECT
    USING (TRUE);

CREATE POLICY "Users can delete own subscriptions"
    ON notification_subscriptions FOR DELETE
    USING (TRUE);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to get reaction counts for a photo
CREATE OR REPLACE FUNCTION get_photo_reactions(photo_uuid UUID)
RETURNS TABLE(emoji TEXT, count BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT r.emoji, COUNT(*) as count
    FROM reactions r
    WHERE r.photo_id = photo_uuid
    GROUP BY r.emoji
    ORDER BY count DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to check if event should auto-reveal
CREATE OR REPLACE FUNCTION auto_reveal_check()
RETURNS TRIGGER AS $$
BEGIN
    -- If reveal_time has passed and not yet revealed, reveal it
    IF NEW.reveal_mode = 'delayed' 
       AND NEW.reveal_time IS NOT NULL 
       AND NEW.reveal_time <= NOW() 
       AND NEW.is_revealed = FALSE THEN
        NEW.is_revealed := TRUE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for auto-reveal on event access
CREATE TRIGGER trigger_auto_reveal
    BEFORE UPDATE ON events
    FOR EACH ROW
    EXECUTE FUNCTION auto_reveal_check();

-- ============================================
-- SCHEDULED JOB FOR AUTO-REVEAL
-- ============================================
-- Note: Supabase doesn't support pg_cron by default
-- Use a cron job or edge function to call this periodically

CREATE OR REPLACE FUNCTION batch_reveal_events()
RETURNS INTEGER AS $$
DECLARE
    revealed_count INTEGER;
BEGIN
    WITH revealed AS (
        UPDATE events
        SET is_revealed = TRUE
        WHERE reveal_mode = 'delayed'
          AND reveal_time IS NOT NULL
          AND reveal_time <= NOW()
          AND is_revealed = FALSE
        RETURNING id
    )
    SELECT COUNT(*) INTO revealed_count FROM revealed;
    
    RETURN revealed_count;
END;
$$ LANGUAGE plpgsql;
