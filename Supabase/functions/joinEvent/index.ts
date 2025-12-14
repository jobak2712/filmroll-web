// Supabase Edge Function: joinEvent
// Deploy with: supabase functions deploy joinEvent

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface JoinEventRequest {
  join_code: string
  guest_name?: string
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    )

    const body: JoinEventRequest = await req.json()

    if (!body.join_code) {
      return new Response(
        JSON.stringify({ error: 'join_code is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Find event by join code
    const { data: event, error: eventError } = await supabaseClient
      .from('events')
      .select('*')
      .eq('join_code', body.join_code.toLowerCase())
      .single()

    if (eventError || !event) {
      return new Response(
        JSON.stringify({ error: 'Event not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check if event is locked
    if (event.is_locked) {
      return new Response(
        JSON.stringify({ error: 'This event is no longer accepting new participants' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check participant cap
    const { count: participantCount } = await supabaseClient
      .from('participants')
      .select('*', { count: 'exact', head: true })
      .eq('event_id', event.id)

    if (participantCount !== null && participantCount >= event.participant_cap) {
      return new Response(
        JSON.stringify({ error: 'This event has reached its participant limit' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create participant
    const { data: participant, error: participantError } = await supabaseClient
      .from('participants')
      .insert({
        event_id: event.id,
        guest_name: body.guest_name || null,
        shots_taken: 0,
      })
      .select()
      .single()

    if (participantError) {
      console.error('Participant error:', participantError)
      return new Response(
        JSON.stringify({ error: 'Failed to join event' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({ 
        participant,
        event: {
          id: event.id,
          title: event.title,
          description: event.description,
          event_date: event.event_date,
          shot_limit_per_guest: event.shot_limit_per_guest,
          reveal_mode: event.reveal_mode,
          reveal_time: event.reveal_time,
          is_revealed: event.is_revealed,
          allow_new_photos: event.allow_new_photos,
        }
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
