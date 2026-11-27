-- =====================================================================
-- MINEXO · Gestión comercial — esquema de base de datos (Supabase)
-- Pegar completo en Supabase → SQL Editor → New query → Run.
-- Se puede volver a ejecutar sin romper nada.
-- =====================================================================

-- ---------- Perfiles de usuario (rol y estado) ----------
create table if not exists public.perfiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  email      text not null,
  nombre     text not null default '',
  rol        text not null default 'vendedor' check (rol in ('admin','vendedor','lector')),
  activo     boolean not null default true,
  created_at timestamptz not null default now()
);

-- Funciones de permiso (security definer para que no dependan de RLS)
create or replace function public.mi_rol() returns text
language sql stable security definer set search_path = public as $$
  select rol from public.perfiles where id = auth.uid() and activo
$$;
create or replace function public.es_activo() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select activo from public.perfiles where id = auth.uid()), false)
$$;
create or replace function public.puede_editar() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(public.mi_rol() in ('admin','vendedor'), false)
$$;
create or replace function public.es_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(public.mi_rol() = 'admin', false)
$$;

-- Al crear un usuario se crea su perfil. El PRIMER usuario queda como admin.
create or replace function public.nuevo_usuario() returns trigger
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  select count(*) into n from public.perfiles;
  insert into public.perfiles (id, email, nombre, rol)
  values (
    new.id, new.email,
    coalesce(new.raw_user_meta_data->>'nombre', split_part(new.email,'@',1)),
    case when n = 0 then 'admin'
         else coalesce(nullif(new.raw_user_meta_data->>'rol',''), 'vendedor') end
  )
  on conflict (id) do nothing;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.nuevo_usuario();

-- ---------- Datos del sistema (documentos JSON, igual que la versión anterior) ----------
create table if not exists public.clientes (
  id text primary key, data jsonb not null,
  updated_at timestamptz not null default now(), updated_by uuid default auth.uid()
);
create table if not exists public.visitas (
  id text primary key, data jsonb not null,
  updated_at timestamptz not null default now(), updated_by uuid default auth.uid()
);
create table if not exists public.viajes (
  id text primary key, data jsonb not null,
  updated_at timestamptz not null default now(), updated_by uuid default auth.uid()
);
create table if not exists public.config (
  id text primary key, data jsonb not null,
  updated_at timestamptz not null default now(), updated_by uuid default auth.uid()
);

create or replace function public.tocar() returns trigger language plpgsql as $$
begin new.updated_at := now(); new.updated_by := auth.uid(); return new; end $$;
do $$ declare t text; begin
  foreach t in array array['clientes','visitas','viajes','config'] loop
    execute format('drop trigger if exists tocar on public.%I', t);
    execute format('create trigger tocar before insert or update on public.%I for each row execute function public.tocar()', t);
  end loop;
end $$;

-- ---------- Archivos adjuntos ----------
create table if not exists public.adjuntos (
  id          uuid primary key default gen_random_uuid(),
  cliente_id  text not null,
  visita_id   text,
  seccion     text not null default 'General',
  nombre      text not null,
  path        text not null unique,
  tipo        text,
  tamano      bigint,
  nota        text,
  subido_por  uuid default auth.uid(),
  subido_nombre text,
  created_at  timestamptz not null default now()
);
create index if not exists adjuntos_cliente on public.adjuntos(cliente_id);

-- ---------- Reglas de acceso (RLS) ----------
alter table public.perfiles enable row level security;
alter table public.clientes enable row level security;
alter table public.visitas  enable row level security;
alter table public.viajes   enable row level security;
alter table public.config   enable row level security;
alter table public.adjuntos enable row level security;

drop policy if exists perfiles_leer on public.perfiles;
create policy perfiles_leer on public.perfiles for select to authenticated
  using (id = auth.uid() or public.es_activo());
drop policy if exists perfiles_admin on public.perfiles;
create policy perfiles_admin on public.perfiles for update to authenticated
  using (public.es_admin()) with check (public.es_admin());

-- clientes: leen todos los activos; crean/editan admin y vendedores; elimina solo admin
drop policy if exists c_leer on public.clientes;
create policy c_leer on public.clientes for select to authenticated using (public.es_activo());
drop policy if exists c_crear on public.clientes;
create policy c_crear on public.clientes for insert to authenticated with check (public.puede_editar());
drop policy if exists c_editar on public.clientes;
create policy c_editar on public.clientes for update to authenticated using (public.puede_editar()) with check (public.puede_editar());
drop policy if exists c_borrar on public.clientes;
create policy c_borrar on public.clientes for delete to authenticated using (public.es_admin());

-- visitas y viajes: admin y vendedores hacen todo
do $$ declare t text; begin
  foreach t in array array['visitas','viajes'] loop
    execute format('drop policy if exists leer on public.%I', t);
    execute format('create policy leer on public.%I for select to authenticated using (public.es_activo())', t);
    execute format('drop policy if exists escribir on public.%I', t);
    execute format('create policy escribir on public.%I for all to authenticated using (public.puede_editar()) with check (public.puede_editar())', t);
  end loop;
end $$;

-- configuración: leen todos, modifica admin
drop policy if exists cfg_leer on public.config;
create policy cfg_leer on public.config for select to authenticated using (public.es_activo());
drop policy if exists cfg_admin on public.config;
create policy cfg_admin on public.config for all to authenticated using (public.es_admin()) with check (public.es_admin());

-- adjuntos: leen todos; suben admin/vendedores; borra admin o quien lo subió
drop policy if exists a_leer on public.adjuntos;
create policy a_leer on public.adjuntos for select to authenticated using (public.es_activo());
drop policy if exists a_subir on public.adjuntos;
create policy a_subir on public.adjuntos for insert to authenticated with check (public.puede_editar());
drop policy if exists a_borrar on public.adjuntos;
create policy a_borrar on public.adjuntos for delete to authenticated
  using (public.es_admin() or (subido_por = auth.uid() and public.puede_editar()));

-- ---------- Almacenamiento de archivos ----------
insert into storage.buckets (id, name, public, file_size_limit)
values ('adjuntos', 'adjuntos', false, 52428800)   -- 50 MB por archivo
on conflict (id) do nothing;

drop policy if exists adj_leer on storage.objects;
create policy adj_leer on storage.objects for select to authenticated
  using (bucket_id = 'adjuntos' and public.es_activo());
drop policy if exists adj_subir on storage.objects;
create policy adj_subir on storage.objects for insert to authenticated
  with check (bucket_id = 'adjuntos' and public.puede_editar());
drop policy if exists adj_borrar on storage.objects;
create policy adj_borrar on storage.objects for delete to authenticated
  using (bucket_id = 'adjuntos' and (public.es_admin() or (owner = auth.uid() and public.puede_editar())));

-- ---------- Tiempo real (para que todos vean los cambios al instante) ----------
do $$ declare t text; begin
  foreach t in array array['clientes','visitas','viajes','config','adjuntos','perfiles'] loop
    begin execute format('alter publication supabase_realtime add table public.%I', t);
    exception when duplicate_object then null; end;
  end loop;
end $$;
alter table public.clientes replica identity full;
alter table public.visitas  replica identity full;
alter table public.viajes   replica identity full;
alter table public.adjuntos replica identity full;
