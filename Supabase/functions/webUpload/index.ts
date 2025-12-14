// Supabase Edge Function: webUpload
// Web-based photo upload for guests

import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

Deno.serve(async (req: Request) => {
  const url = new URL(req.url)
  const pathParts = url.pathname.split("/")
  const joinCode = pathParts[pathParts.length - 1] || ""

  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    })
  }

  // POST - handle photo upload
  if (req.method === "POST") {
    try {
      const supabase = createClient(
        Deno.env.get("SUPABASE_URL")!,
        Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
      )
      
      const formData = await req.formData()
      const photo = formData.get("photo") as File
      const eventId = formData.get("event_id") as string
      const participantId = formData.get("participant_id") as string

      if (!photo || !eventId || !participantId) {
        return Response.json({ error: "Missing required fields" }, { status: 400 })
      }

      const fileName = `${Date.now()}_${crypto.randomUUID()}.jpg`
      const storagePath = `${eventId}/${participantId}/${fileName}`
      const arrayBuffer = await photo.arrayBuffer()

      const { error: uploadError } = await supabase.storage
        .from("photos")
        .upload(storagePath, arrayBuffer, { contentType: "image/jpeg" })

      if (uploadError) {
        return Response.json({ error: "Upload failed" }, { status: 500 })
      }

      await supabase.from("photos").insert({
        event_id: eventId,
        participant_id: participantId,
        storage_path: storagePath,
        file_size: photo.size,
        is_uploaded: true,
      })

      return Response.json({ success: true, path: storagePath })
    } catch (e) {
      return Response.json({ error: String(e) }, { status: 500 })
    }
  }

  // GET - return JSON with event data
  // The HTML UI should be hosted separately (GitHub Pages, Vercel, etc.)
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  )

  const { data: event } = await supabase
    .from("events")
    .select("id, title, shot_limit_per_guest, join_code")
    .eq("join_code", joinCode.toLowerCase())
    .single()

  if (!event) {
    return Response.json({ error: "Event not found", joinCode }, { status: 404 })
  }

  // Return event data as JSON - UI must be hosted elsewhere
  return Response.json({
    event: {
      id: event.id,
      title: event.title,
      shotLimit: event.shot_limit_per_guest,
      joinCode: event.join_code
    },
    endpoints: {
      upload: `${Deno.env.get("SUPABASE_URL")}/functions/v1/webUpload`,
      join: `${Deno.env.get("SUPABASE_URL")}/functions/v1/joinEvent`
    },
    apiKey: Deno.env.get("SUPABASE_ANON_KEY")
  })
})