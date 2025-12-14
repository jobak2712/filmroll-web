// Supabase Edge Function: slideshow
// Live slideshow display for TVs/projectors at events

import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    })
  }

  const url = new URL(req.url)
  const pathParts = url.pathname.split("/")
  const joinCode = pathParts[pathParts.length - 1] || url.searchParams.get("code") || ""
  const interval = parseInt(url.searchParams.get("interval") || "5") * 1000

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
  )

  const { data: event } = await supabase
    .from("events")
    .select("*")
    .eq("join_code", joinCode.toLowerCase())
    .single()

  if (!event) {
    const errorHtml = `<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Error</title></head>
<body style="background:#000;color:#fff;font-family:sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;margin:0">
<div style="text-align:center"><h1 style="color:#FF6B35">FilmRoll</h1><p>Event not found</p></div>
</body></html>`
    return new Response(errorHtml, {
      status: 404,
      headers: { 
        "Content-Type": "text/html; charset=utf-8",
        "X-Content-Type-Options": "nosniff"
      },
    })
  }

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL")
  const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")

  const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${event.title} - Live Slideshow</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#000;color:#fff;font-family:-apple-system,sans-serif;overflow:hidden;height:100vh;width:100vw}
.slideshow{position:relative;width:100%;height:100%}
.slide{position:absolute;top:0;left:0;width:100%;height:100%;opacity:0;transition:opacity 1s;display:flex;align-items:center;justify-content:center}
.slide.active{opacity:1}
.slide img{max-width:90%;max-height:85%;object-fit:contain;border-radius:16px;box-shadow:0 20px 60px rgba(0,0,0,0.5)}
.photo-info{position:absolute;bottom:40px;left:50%;transform:translateX(-50%);text-align:center;background:rgba(0,0,0,0.7);backdrop-filter:blur(20px);padding:16px 32px;border-radius:16px}
.guest-name{font-size:24px;font-weight:600;margin-bottom:4px}
.caption{font-size:18px;color:rgba(255,255,255,0.7);font-style:italic}
.header{position:absolute;top:0;left:0;right:0;padding:24px 40px;display:flex;justify-content:space-between;align-items:center;background:linear-gradient(to bottom,rgba(0,0,0,0.8),transparent);z-index:10}
.event-title{font-size:28px;font-weight:700}
.photo-count{display:flex;align-items:center;gap:12px;font-size:20px}
.count-badge{background:#FF6B35;padding:8px 16px;border-radius:20px;font-weight:600}
.qr-corner{position:absolute;bottom:40px;right:40px;text-align:center;background:#fff;padding:16px;border-radius:16px}
.qr-corner img{width:120px;height:120px}
.qr-corner p{color:#333;font-size:14px;margin-top:8px;font-weight:600}
.waiting{display:flex;flex-direction:column;align-items:center;justify-content:center;height:100%;text-align:center}
.waiting-icon{font-size:80px;margin-bottom:24px;animation:pulse 2s infinite}
@keyframes pulse{0%,100%{transform:scale(1)}50%{transform:scale(1.1)}}
.waiting h2{font-size:36px;margin-bottom:16px}
.waiting p{font-size:20px;color:rgba(255,255,255,0.6)}
.new-photo-alert{position:fixed;top:50%;left:50%;transform:translate(-50%,-50%) scale(0);background:#FF6B35;padding:24px 48px;border-radius:20px;font-size:24px;font-weight:600;z-index:100;transition:transform 0.3s}
.new-photo-alert.show{transform:translate(-50%,-50%) scale(1)}
</style>
</head>
<body>
<div class="slideshow">
<div class="header">
<div class="event-title">📸 ${event.title}</div>
<div class="photo-count">
<span id="photoCount">0</span> photos
<span class="count-badge">● LIVE</span>
</div>
</div>
<div id="slidesContainer"></div>
<div class="waiting" id="waitingScreen">
<div class="waiting-icon">📷</div>
<h2>Waiting for photos...</h2>
<p>Scan the QR code to start capturing!</p>
</div>
<div class="qr-corner">
<img src="https://api.qrserver.com/v1/create-qr-code/?size=120x120&data=${encodeURIComponent(`https://filmroll.app/join/${joinCode}`)}" alt="QR">
<p>Join: ${joinCode.toUpperCase()}</p>
</div>
<div class="new-photo-alert" id="newPhotoAlert">📸 New photo!</div>
</div>
<script>
const EVENT_ID="${event.id}";
const SUPABASE_URL="${SUPABASE_URL}";
const SUPABASE_KEY="${SUPABASE_ANON_KEY}";
const INTERVAL=${interval};
let photos=[],currentIndex=0,lastPhotoCount=0;

async function fetchPhotos(){
try{
const res=await fetch(SUPABASE_URL+"/functions/v1/getEventPhotos?event_id="+EVENT_ID+"&is_host=true",{
headers:{"apikey":SUPABASE_KEY,"Authorization":"Bearer "+SUPABASE_KEY}
});
const data=await res.json();
if(data.photos&&data.photos.length>0){
if(data.photos.length>lastPhotoCount&&lastPhotoCount>0)showNewPhotoAlert();
lastPhotoCount=data.photos.length;
photos=data.photos;
document.getElementById("photoCount").textContent=photos.length;
document.getElementById("waitingScreen").style.display="none";
renderSlides();
}
}catch(e){console.error(e)}
}

function renderSlides(){
document.getElementById("slidesContainer").innerHTML=photos.map((p,i)=>
\`<div class="slide \${i===currentIndex?"active":""}" data-index="\${i}">
<img src="\${p.url||""}" alt="Photo">
<div class="photo-info">
<div class="guest-name">\${p.participants?.guest_name||"Guest"}</div>
\${p.caption?\`<div class="caption">"\${p.caption}"</div>\`:""}
</div>
</div>\`).join("");
}

function nextSlide(){
if(!photos.length)return;
const slides=document.querySelectorAll(".slide");
slides[currentIndex]?.classList.remove("active");
currentIndex=(currentIndex+1)%photos.length;
slides[currentIndex]?.classList.add("active");
}

function showNewPhotoAlert(){
const a=document.getElementById("newPhotoAlert");
a.classList.add("show");
setTimeout(()=>a.classList.remove("show"),2000);
}

fetchPhotos();
setInterval(fetchPhotos,10000);
setInterval(nextSlide,INTERVAL);
</script>
</body>
</html>`

  return new Response(html, {
    status: 200,
    headers: { 
      "Content-Type": "text/html; charset=utf-8",
      "X-Content-Type-Options": "nosniff"
    },
  })
})