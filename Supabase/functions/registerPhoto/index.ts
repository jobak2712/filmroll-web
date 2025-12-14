// Supabase Edge Function: registerPhoto
// Deploy with: supabase functions deploy registerPhoto

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RegisterPhotoRequest {
  event_id: string
  participant_id: string
  storage_path: string
  file_size: number
  captured_at?: string
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

    const body: RegisterPhotoRequest = await req.json()

    // Validate required fields
    if (!body.event_id || !body.participant_id || !body.storage_path) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verify participant and get current shot count
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

    // Double-check shot limit
    if (participant.shots_taken >= participant.events.shot_limit_per_guest) {
      return new Response(
        JSON.stringify({ error: 'Shot limit reached' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create photo record
    const { data: photo, error: photoError } = await supabaseClient
      .from('photos')
      .insert({
        event_id: body.event_id,
        participant_id: body.participant_id,
        storage_path: body.storage_path,
        file_size: body.file_size || 0,
        captured_at: body.captured_at || new Date().toISOString(),
        uploaded_at: new Date().toISOString(),
        is_uploaded: true,
      })
      .select()
      .single()

    if (photoError) {
      console.error('Photo insert error:', photoError)
      return new Response(
        JSON.stringify({ error: 'Failed to register photo' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Update participant shot count
    const { error: updateError } = await supabaseClient
      .from('participants')
      .update({ shots_taken: participant.shots_taken + 1 })
      .eq('id', body.participant_id)

    if (updateError) {
      console.error('Update error:', updateError)
      // Don't fail the request, photo is already saved
    }

    return new Response(
      JSON.stringify({
        photo,
        shots_taken: participant.shots_taken + 1,
        shots_remaining: participant.events.shot_limit_per_guest - participant.shots_taken - 1,
      }),
      { status: 201, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
