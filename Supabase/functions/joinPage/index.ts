// Supabase Edge Function: joinPage
// Serves a smart landing page for joining events
// Deploy with: supabase functions deploy joinPage

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  const url = new URL(req.url)
  const pathParts = url.pathname.split('/')
  const joinCode = pathParts[pathParts.length - 1] || url.searchParams.get('code') || ''
  
  // Fetch event details
  let eventTitle = "FilmRoll Event"
  let eventDescription = "Join the event and capture moments together"
  
  if (joinCode) {
    try {
      const supabase = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_ANON_KEY') ?? ''
      )
      
      const { data: event } = await supabase
        .from('events')
        .select('title, description')
        .eq('join_code', joinCode.toLowerCase())
        .single()
      
      if (event) {
        eventTitle = event.title
        eventDescription = event.description || "Join the event and capture moments together"
      }
    } catch (e) {
      console.error('Error fetching event:', e)
    }
  }

  // App Store URL (replace with your actual App Store ID when published)
  const appStoreUrl = "https://apps.apple.com/app/filmroll/id000000000"
  const deepLink = `filmroll://join/${joinCode}`
  
  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>${eventTitle} - FilmRoll</title>
  
  <!-- Open Graph / Social -->
  <meta property="og:title" content="${eventTitle}">
  <meta property="og:description" content="${eventDescription}">
  <meta property="og:image" content="https://filmroll.app/og-image.png">
  <meta property="og:url" content="https://filmroll.app/join/${joinCode}">
  <meta name="twitter:card" content="summary_large_image">
  
  <!-- Smart App Banner for Safari -->
  <meta name="apple-itunes-app" content="app-id=000000000, app-argument=${deepLink}">
  
  <!-- Universal Link attempt -->
  <meta http-equiv="refresh" content="0;url=${deepLink}">
  
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%);
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 24px;
      color: white;
    }
    
    .container {
      max-width: 400px;
      width: 100%;
      text-align: center;
    }
    
    .logo {
      width: 100px;
      height: 100px;
      background: #FF6B35;
      border-radius: 24px;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 32px;
      font-size: 48px;
      box-shadow: 0 20px 40px rgba(255, 107, 53, 0.3);
    }
    
    .event-card {
      background: rgba(255, 255, 255, 0.1);
      backdrop-filter: blur(20px);
      border-radius: 24px;
      padding: 32px 24px;
      margin-bottom: 32px;
      border: 1px solid rgba(255, 255, 255, 0.1);
    }
    
    .badge {
      display: inline-block;
      background: rgba(255, 107, 53, 0.2);
      color: #FF6B35;
      padding: 6px 16px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 1px;
      margin-bottom: 16px;
    }
    
    h1 {
      font-size: 28px;
      font-weight: 700;
      margin-bottom: 12px;
      line-height: 1.2;
    }
    
    .description {
      color: rgba(255, 255, 255, 0.7);
      font-size: 16px;
      line-height: 1.5;
      margin-bottom: 24px;
    }
    
    .code-display {
      background: rgba(0, 0, 0, 0.3);
      border-radius: 12px;
      padding: 16px;
      font-family: 'SF Mono', Monaco, monospace;
      font-size: 24px;
      font-weight: 700;
      letter-spacing: 4px;
      color: #FF6B35;
    }
    
    .download-btn {
      display: block;
      width: 100%;
      background: white;
      color: #1a1a1a;
      padding: 18px 32px;
      border-radius: 16px;
      font-size: 17px;
      font-weight: 600;
      text-decoration: none;
      margin-bottom: 16px;
      transition: transform 0.2s, box-shadow 0.2s;
    }
    
    .download-btn:hover {
      transform: translateY(-2px);
      box-shadow: 0 10px 30px rgba(255, 255, 255, 0.2);
    }
    
    .download-btn img {
      height: 20px;
      vertical-align: middle;
      margin-right: 8px;
    }
    
    .divider {
      display: flex;
      align-items: center;
      margin: 20px 0;
      color: rgba(255, 255, 255, 0.4);
      font-size: 14px;
    }
    
    .divider::before,
    .divider::after {
      content: '';
      flex: 1;
      height: 1px;
      background: rgba(255, 255, 255, 0.2);
    }
    
    .divider span {
      padding: 0 16px;
    }
    
    .web-btn {
      display: block;
      width: 100%;
      background: rgba(255, 255, 255, 0.1);
      border: 1px solid rgba(255, 255, 255, 0.2);
      color: white;
      padding: 16px 32px;
      border-radius: 16px;
      font-size: 16px;
      font-weight: 500;
      text-decoration: none;
      margin-bottom: 24px;
      transition: transform 0.2s, background 0.2s;
    }
    
    .web-btn:hover {
      transform: translateY(-2px);
      background: rgba(255, 255, 255, 0.15);
    }
    
    .open-btn {
      display: block;
      width: 100%;
      background: #FF6B35;
      color: white;
      padding: 18px 32px;
      border-radius: 16px;
      font-size: 17px;
      font-weight: 600;
      text-decoration: none;
      margin-bottom: 24px;
      transition: transform 0.2s, box-shadow 0.2s;
    }
    
    .open-btn:hover {
      transform: translateY(-2px);
      box-shadow: 0 10px 30px rgba(255, 107, 53, 0.4);
    }
    
    .features {
      display: flex;
      justify-content: center;
      gap: 32px;
      margin-top: 32px;
      color: rgba(255, 255, 255, 0.6);
      font-size: 13px;
    }
    
    .feature {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 8px;
    }
    
    .feature-icon {
      font-size: 24px;
    }
    
    .footer {
      margin-top: 48px;
      color: rgba(255, 255, 255, 0.4);
      font-size: 13px;
    }
    
    .footer a {
      color: rgba(255, 255, 255, 0.6);
      text-decoration: none;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">📸</div>
    
    <div class="event-card">
      <div class="badge">You're Invited</div>
      <h1>${eventTitle}</h1>
      <p class="description">${eventDescription}</p>
      <div class="code-display">${joinCode.toUpperCase()}</div>
    </div>
    
    <a href="${deepLink}" class="open-btn" id="openApp">
      Open in FilmRoll
    </a>
    
    <a href="${appStoreUrl}" class="download-btn">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" style="vertical-align: middle; margin-right: 8px;">
        <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
      </svg>
      Download on App Store
    </a>
    
    <div class="divider">
      <span>or</span>
    </div>
    
    <a href="${Deno.env.get('SUPABASE_URL')}/functions/v1/webUpload/${joinCode}" class="web-btn">
      🌐 Upload from Browser (No App Needed)
    </a>
    
    <div class="features">
      <div class="feature">
        <span class="feature-icon">📷</span>
        <span>Capture</span>
      </div>
      <div class="feature">
        <span class="feature-icon">⏳</span>
        <span>Wait</span>
      </div>
      <div class="feature">
        <span class="feature-icon">✨</span>
        <span>Reveal</span>
      </div>
    </div>
    
    <div class="footer">
      <p>FilmRoll - Capture moments together</p>
    </div>
  </div>
  
  <script>
    // Try to open the app immediately
    window.location.href = "${deepLink}";
    
    // If still here after 2 seconds, they don't have the app
    setTimeout(function() {
      document.getElementById('openApp').style.display = 'none';
    }, 2000);
  </script>
</body>
</html>`

  return new Response(html, {
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
    },
  })
})
