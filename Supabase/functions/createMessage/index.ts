// Supabase Edge Function: createMessage
// Deploy with: supabase functions deploy createMessage

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface CreateMessageRequest {
  event_id: string
  participant_id: string
  participant_name?: string
  content: string
  message_type?: 'text' | 'voice' | 'video'
  media_url?: string
  duration_seconds?: number
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

    const body: CreateMessageRequest = await req.json()

    // Validate required fields
    if (!body.event_id || !body.content) {
      return new Response(
        JSON.stringify({ error: 'event_id and content are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verify event exists
    const { data: event, error: eventError } = await supabaseClient
      .from('events')
      .select('id, host_id')
      .eq('id', body.event_id)
      .single()

    if (eventError || !event) {
      return new Response(
        JSON.stringify({ error: 'Event not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create message
    const { data: message, error: messageError } = await supabaseClient
      .from('messages')
      .insert({
        event_id: body.event_id,
        participant_id: body.participant_id || null,
        participant_name: body.participant_name || 'Anonymous Guest',
        content: body.content,
        message_type: body.message_type || 'text',
        media_url: body.media_url || null,
        duration_seconds: body.duration_seconds || null,
      })
      .select()
      .single()

    if (messageError) {
      console.error('Message error:', messageError)
      return new Response(
        JSON.stringify({ error: 'Failed to create message' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({ message }),
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
