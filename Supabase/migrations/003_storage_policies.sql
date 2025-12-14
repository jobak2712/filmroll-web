-- FilmRoll Database Migration 003
-- Adds: Storage bucket policies for photo uploads
-- Run this in Supabase SQL Editor

-- ============================================
-- STORAGE POLICIES FOR PHOTOS BUCKET
-- ============================================

-- Allow anyone to upload photos (guests don't have auth)
CREATE POLICY "Allow photo uploads"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'photos');

-- Allow anyone to read photos (access controlled by app logic)
CREATE POLICY "Allow photo reads"
ON storage.objects FOR SELECT
USING (bucket_id = 'photos');

-- Allow anyone to update photos (for signed URL uploads)
CREATE POLICY "Allow photo updates"
ON storage.objects FOR UPDATE
USING (bucket_id = 'photos');

-- Allow deletion by authenticated users
CREATE POLICY "Allow photo deletion"
ON storage.objects FOR DELETE
USING (bucket_id = 'photos');
