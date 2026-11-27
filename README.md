# MINEXO · Gestión comercial

Sistema de gestión comercial de Minexo: clientes, relevamientos, visitas, viajes con rutas optimizadas, calendario con feriados, archivos adjuntos y usuarios con roles.

- **Página:** `index.html` + `config.js` + `geo/` (capas del mapa). Sitio estático, se publica en Netlify sin build (`netlify.toml`).
- **Base de datos, usuarios y archivos:** Supabase. Esquema en `supabase/schema.sql`; función de administración de usuarios en `supabase/functions/admin-usuarios/`.
- **Instalación y uso:** ver `GUIA-INSTALACION.md`.

Cada cambio que se sube a la rama `main` se publica automáticamente en Netlify.
