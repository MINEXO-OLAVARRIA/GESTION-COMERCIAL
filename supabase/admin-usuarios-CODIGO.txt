// MINEXO · función "admin-usuarios"
// Permite al administrador crear usuarios, cambiar contraseñas y eliminarlos
// desde la pantalla Ajustes del sistema. Solo responde a usuarios con rol admin.
import { createClient } from "npm:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const res = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const url = Deno.env.get("SUPABASE_URL")!;
    let key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
    if (!key) { try { const k = JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS") || "{}"); key = k.default || Object.values(k)[0] || ""; } catch (_) { /* */ } }
    if (!key) return res({ error: "La función no encuentra la clave secreta del proyecto" }, 500);
    const admin = createClient(url, key, { auth: { persistSession: false } });
    const jwt = (req.headers.get("Authorization") || "").replace("Bearer ", "");
    const { data: { user } } = await admin.auth.getUser(jwt);
    if (!user) return res({ error: "Sesión no válida" }, 401);
    const { data: yo } = await admin.from("perfiles").select("rol,activo").eq("id", user.id).single();
    if (!yo || yo.rol !== "admin" || !yo.activo) return res({ error: "Solo un administrador puede gestionar usuarios" }, 403);

    const b = await req.json();
    const ROLES = ["admin", "vendedor", "lector"];

    if (b.accion === "crear") {
      const email = String(b.email || "").trim().toLowerCase();
      const nombre = String(b.nombre || "").trim();
      const rol = ROLES.includes(b.rol) ? b.rol : "vendedor";
      if (!email || !nombre || String(b.password || "").length < 8)
        return res({ error: "Completá nombre, email y una contraseña de al menos 8 caracteres" }, 400);
      const { data, error } = await admin.auth.admin.createUser({
        email, password: b.password, email_confirm: true, user_metadata: { nombre, rol },
      });
      if (error) return res({ error: error.message.includes("already") ? "Ya existe un usuario con ese email" : error.message }, 400);
      await admin.from("perfiles").upsert({ id: data.user.id, email, nombre, rol, activo: true });
      return res({ ok: true, id: data.user.id });
    }

    if (b.accion === "password") {
      if (String(b.password || "").length < 8) return res({ error: "La contraseña debe tener al menos 8 caracteres" }, 400);
      const { error } = await admin.auth.admin.updateUserById(b.id, { password: b.password });
      if (error) return res({ error: error.message }, 400);
      return res({ ok: true });
    }

    if (b.accion === "eliminar") {
      if (b.id === user.id) return res({ error: "No podés eliminar tu propio usuario" }, 400);
      const { error } = await admin.auth.admin.deleteUser(b.id);
      if (error) return res({ error: error.message }, 400);
      return res({ ok: true });
    }

    return res({ error: "Acción desconocida" }, 400);
  } catch (e) {
    return res({ error: String(e?.message || e) }, 500);
  }
});
