-- FilmRoll Database Migration 004
-- Adds: Push notifications, video/voice messages, print orders, slideshow settings
-- This is a standalone migration - no foreign key dependencies

-- ============================================
-- PUSH NOTIFICATION TOKENS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS push_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    host_id UUID,
    participant_id UUID,
    device_token TEXT NOT NULL,
    platform TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(device_token)
);

CREATE INDEX IF NOT EXISTS idx_push_tokens_host ON push_tokens(host_id);
CREATE INDEX IF NOT EXISTS idx_push_tokens_participant ON push_tokens(participant_id);

-- ============================================
-- SCHEDULED NOTIFICATIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS scheduled_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL,
    notification_type TEXT NOT NULL CHECK (notification_type IN ('reveal', 'reminder', 'custom')),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    scheduled_for TIMESTAMPTZ NOT NULL,
    sent_at TIMESTAMPTZ,
    is_sent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_scheduled_notifications_event ON scheduled_notifications(event_id);
CREATE INDEX IF NOT EXISTS idx_scheduled_notifications_pending ON scheduled_notifications(scheduled_for) WHERE is_sent = FALSE;

-- ============================================
-- PRINT ORDERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS print_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL,
    host_id UUID NOT NULL,
    
    -- Order details
    order_status TEXT NOT NULL DEFAULT 'pending' CHECK (order_status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
    product_type TEXT NOT NULL CHECK (product_type IN ('prints', 'album', 'canvas', 'poster', 'photobook')),
    quantity INTEGER NOT NULL DEFAULT 1,
    
    -- Selected photos
    photo_ids UUID[] NOT NULL,
    
    -- Shipping
    shipping_name TEXT,
    shipping_address TEXT,
    shipping_city TEXT,
    shipping_state TEXT,
    shipping_zip TEXT,
    shipping_country TEXT DEFAULT 'US',
    
    -- Payment
    subtotal_cents INTEGER NOT NULL DEFAULT 0,
    shipping_cents INTEGER NOT NULL DEFAULT 0,
    tax_cents INTEGER NOT NULL DEFAULT 0,
    total_cents INTEGER NOT NULL DEFAULT 0,
    payment_intent_id TEXT,
    payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'refunded', 'failed')),
    
    -- Fulfillment
    tracking_number TEXT,
    tracking_url TEXT,
    fulfilled_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_print_orders_event ON print_orders(event_id);
CREATE INDEX IF NOT EXISTS idx_print_orders_host ON print_orders(host_id);
CREATE INDEX IF NOT EXISTS idx_print_orders_status ON print_orders(order_status);

-- ============================================
-- SLIDESHOW SETTINGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS slideshow_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL UNIQUE,
    
    -- Display settings
    interval_seconds INTEGER DEFAULT 5,
    transition_type TEXT DEFAULT 'fade' CHECK (transition_type IN ('fade', 'slide', 'zoom', 'none')),
    show_captions BOOLEAN DEFAULT TRUE,
    show_guest_names BOOLEAN DEFAULT TRUE,
    show_qr_code BOOLEAN DEFAULT TRUE,
    
    -- Styling
    background_color TEXT DEFAULT '#000000',
    text_color TEXT DEFAULT '#FFFFFF',
    accent_color TEXT DEFAULT '#FF6B35',
    
    -- Content
    custom_message TEXT,
    logo_url TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to increment shots_taken (for web upload)
CREATE OR REPLACE FUNCTION increment_shots_taken(p_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE participants 
    SET shots_taken = shots_taken + 1 
    WHERE id = p_id;
EXCEPTION WHEN OTHERS THEN
    -- Silently fail if participants table doesn't exist
    NULL;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- RLS POLICIES
-- ============================================

ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduled_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE print_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE slideshow_settings ENABLE ROW LEVEL SECURITY;

-- Push tokens - anyone can manage (for guests)
DROP POLICY IF EXISTS "Anyone can manage push tokens" ON push_tokens;
CREATE POLICY "Anyone can manage push tokens"
    ON push_tokens FOR ALL
    USING (TRUE);

-- Scheduled notifications - anyone can view
DROP POLICY IF EXISTS "Anyone can view notifications" ON scheduled_notifications;
CREATE POLICY "Anyone can view notifications"
    ON scheduled_notifications FOR SELECT
    USING (TRUE);

DROP POLICY IF EXISTS "Anyone can insert notifications" ON scheduled_notifications;
CREATE POLICY "Anyone can insert notifications"
    ON scheduled_notifications FOR INSERT
    WITH CHECK (TRUE);

-- Print orders - anyone can manage (auth checked in app)
DROP POLICY IF EXISTS "Anyone can manage print orders" ON print_orders;
CREATE POLICY "Anyone can manage print orders"
    ON print_orders FOR ALL
    USING (TRUE);

-- Slideshow settings - anyone can view/manage
DROP POLICY IF EXISTS "Anyone can manage slideshow settings" ON slideshow_settings;
CREATE POLICY "Anyone can manage slideshow settings"
    ON slideshow_settings FOR ALL
    USING (TRUE);
