// Supabase Edge Function: createEvent
// Deploy with: supabase functions deploy createEvent

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface CreateEventRequest {
  title: string
  description?: string
  event_date: string
  shot_limit_per_guest: number
  participant_cap: number
  reveal_mode: 'instant' | 'delayed'
  reveal_time?: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get authenticated user
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser()
    
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized', details: authError?.message }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse request body
    const body: CreateEventRequest = await req.json()

    // Validate required fields
    if (!body.title || !body.event_date) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: title, event_date' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate reveal mode
    if (body.reveal_mode === 'delayed' && !body.reveal_time) {
      return new Response(
        JSON.stringify({ error: 'reveal_time is required for delayed reveal mode' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // First, ensure user exists in users table (upsert)
    const { error: userError } = await supabaseClient
      .from('users')
      .upsert({
        id: user.id,
        email: user.email,
        display_name: user.user_metadata?.display_name || null,
        avatar_url: user.user_metadata?.avatar_url || null,
      }, { onConflict: 'id' })

    if (userError) {
      console.error('User upsert error:', userError)
      // Continue anyway - user might already exist
    }

    // Create event
    const { data: event, error: insertError } = await supabaseClient
      .from('events')
      .insert({
        host_id: user.id,
        title: body.title,
        description: body.description,
        event_date: body.event_date,
        shot_limit_per_guest: body.shot_limit_per_guest || 12,
        participant_cap: body.participant_cap || 25,
        reveal_mode: body.reveal_mode || 'instant',
        reveal_time: body.reveal_time,
      })
      .select()
      .single()

    if (insertError) {
      console.error('Insert error:', insertError)
      return new Response(
        JSON.stringify({ error: 'Failed to create event', details: insertError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({ event }),
      { status: 201, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
