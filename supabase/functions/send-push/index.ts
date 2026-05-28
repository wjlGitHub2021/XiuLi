import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  const { user_id, title, body } = await req.json();

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  // Get active device tokens for the target user
  const { data: devices } = await supabase
    .from("user_devices")
    .select("device_token")
    .eq("user_id", user_id)
    .eq("is_active", true);

  if (!devices || devices.length === 0) {
    return new Response(JSON.stringify({ sent: 0 }), {
      headers: { "Content-Type": "application/json" },
    });
  }

  // TODO: Implement APNs sending when credentials are configured
  // Required env vars: APNS_KEY_ID, APNS_TEAM_ID, APNS_PRIVATE_KEY, APNS_BUNDLE_ID
  // Use HTTP/2 to api.push.apple.com with JWT auth

  return new Response(
    JSON.stringify({ sent: 0, message: "APNs credentials not configured yet" }),
    { headers: { "Content-Type": "application/json" } }
  );
});
