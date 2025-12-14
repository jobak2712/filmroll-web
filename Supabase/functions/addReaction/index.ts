// Supabase Edge Function: addReaction
// Deploy with: supabase functions deploy addReaction

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface AddReactionRequest {
  photo_id: string
  participant_id?: string
  emoji: string
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

    const body: AddReactionRequest = await req.json()

    // Validate required fields
    if (!body.photo_id || !body.emoji) {
      return new Response(
        JSON.stringify({ error: 'photo_id and emoji are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate emoji (basic check)
    const validEmojis = ['❤️', '😂', '😍', '🔥', '👏', '😮', '🎉', '💯']
    if (!validEmojis.includes(body.emoji)) {
      return new Response(
        JSON.stringify({ error: 'Invalid emoji' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check if reaction already exists (toggle behavior)
    const { data: existing } = await supabaseClient
      .from('reactions')
      .select('id')
      .eq('photo_id', body.photo_id)
      .eq('participant_id', body.participant_id || null)
      .eq('emoji', body.emoji)
      .single()

    if (existing) {
      // Remove existing reaction (toggle off)
      await supabaseClient
        .from('reactions')
        .delete()
        .eq('id', existing.id)

      return new Response(
        JSON.stringify({ action: 'removed', emoji: body.emoji }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Add new reaction
    const { data: reaction, error: reactionError } = await supabaseClient
      .from('reactions')
      .insert({
        photo_id: body.photo_id,
        participant_id: body.participant_id || null,
        emoji: body.emoji,
      })
      .select()
      .single()

    if (reactionError) {
      console.error('Reaction error:', reactionError)
      return new Response(
        JSON.stringify({ error: 'Failed to add reaction' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get updated reaction counts
    const { data: counts } = await supabaseClient
      .rpc('get_photo_reactions', { photo_uuid: body.photo_id })

    return new Response(
      JSON.stringify({ 
        action: 'added',
        reaction,
        counts: counts || []
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
