// Supabase Edge Function: signPhotoUpload
// Deploy with: supabase functions deploy signPhotoUpload

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface SignUploadRequest {
  event_id: string
  participant_id: string
  file_name: string
  content_type: string
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const body: SignUploadRequest = await req.json()

    // Validate required fields
    if (!body.event_id || !body.participant_id || !body.file_name) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verify participant exists and belongs to event
    const { data: participant, error: participantError } = await supabaseClient
      .from('participants')
      .select('*, events(*)')
      .eq('id', body.participant_id)
      .eq('event_id', body.event_id)
      .single()

    if (participantError || !participant) {
      return new Response(
        JSON.stringify({ error: 'Invalid participant or event' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check if event allows new photos
    if (!participant.events.allow_new_photos) {
      return new Response(
        JSON.stringify({ error: 'This event is no longer accepting photos' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check shot limit
    if (participant.shots_taken >= participant.events.shot_limit_per_guest) {
      return new Response(
        JSON.stringify({ error: 'Shot limit reached' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Generate storage path
    const storagePath = `${body.event_id}/${body.participant_id}/${Date.now()}_${body.file_name}`

    // Create signed upload URL (valid for 5 minutes)
    const { data: signedUrl, error: signError } = await supabaseClient
      .storage
      .from('photos')
      .createSignedUploadUrl(storagePath)

    if (signError) {
      console.error('Sign error:', signError)
      return new Response(
        JSON.stringify({ error: 'Failed to create upload URL' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({
        signed_url: signedUrl.signedUrl,
        storage_path: storagePath,
        token: signedUrl.token,
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
