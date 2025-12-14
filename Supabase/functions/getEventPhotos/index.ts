// Supabase Edge Function: getEventPhotos
// Deploy with: supabase functions deploy getEventPhotos

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const url = new URL(req.url)
    const eventId = url.searchParams.get('event_id')
    const participantId = url.searchParams.get('participant_id')
    const isHost = url.searchParams.get('is_host') === 'true'

    if (!eventId) {
      return new Response(
        JSON.stringify({ error: 'event_id is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get event details
    const { data: event, error: eventError } = await supabaseClient
      .from('events')
      .select('*')
      .eq('id', eventId)
      .single()

    if (eventError || !event) {
      return new Response(
        JSON.stringify({ error: 'Event not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check if user can view photos
    const canViewPhotos = isHost || 
                          event.is_revealed || 
                          event.reveal_mode === 'instant' ||
                          (event.reveal_time && new Date(event.reveal_time) <= new Date())

    if (!canViewPhotos && !isHost) {
      return new Response(
        JSON.stringify({ 
          error: 'Photos are not yet revealed',
          reveal_time: event.reveal_time,
          is_revealed: event.is_revealed,
        }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get photos
    const { data: photos, error: photosError } = await supabaseClient
      .from('photos')
      .select(`
        *,
        participants (
          guest_name
        )
      `)
      .eq('event_id', eventId)
      .eq('is_uploaded', true)
      .order('captured_at', { ascending: false })

    if (photosError) {
      console.error('Photos error:', photosError)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch photos' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Generate signed URLs for each photo
    const photosWithUrls = await Promise.all(
      photos.map(async (photo) => {
        const { data: signedUrl, error: signError } = await supabaseClient
          .storage
          .from('photos')
          .createSignedUrl(photo.storage_path, 3600) // 1 hour expiry

        if (signError) {
          console.error('Sign URL error for', photo.storage_path, ':', signError)
        }

        return {
          ...photo,
          url: signedUrl?.signedUrl || null,
          thumbnail_url: photo.thumbnail_path ? 
            (await supabaseClient.storage.from('photos').createSignedUrl(photo.thumbnail_path, 3600)).data?.signedUrl : 
            null,
        }
      })
    )

    return new Response(
      JSON.stringify({
        photos: photosWithUrls,
        total_count: photos.length,
        event: {
          title: event.title,
          is_revealed: event.is_revealed,
          reveal_mode: event.reveal_mode,
        },
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
