-- ============================================================
-- Tabla y políticas para cierre forzado de sesiones (admin)
-- Ejecutar en Supabase → SQL Editor
-- ============================================================

-- 1) Tabla (si aún no existe)
create table if not exists public.sesiones_activas (
  id text primary key,
  usuario text not null,
  device_id text,
  nombre_dispositivo text,
  ultimo_ping timestamptz default now(),
  conectado_en timestamptz default now(),
  forzar_cierre boolean not null default false
);

-- Índices útiles
create index if not exists idx_sesiones_ultimo_ping on public.sesiones_activas (ultimo_ping desc);
create index if not exists idx_sesiones_usuario on public.sesiones_activas (usuario);

-- 2) Activar RLS
alter table public.sesiones_activas enable row level security;

-- 3) Quitar políticas viejas (por si existen y bloquean)
drop policy if exists "sesiones_select" on public.sesiones_activas;
drop policy if exists "sesiones_insert" on public.sesiones_activas;
drop policy if exists "sesiones_update" on public.sesiones_activas;
drop policy if exists "sesiones_delete" on public.sesiones_activas;
drop policy if exists "auth all sesiones_activas" on public.sesiones_activas;
drop policy if exists "sesiones authenticated all" on public.sesiones_activas;

-- 4) Políticas abiertas para usuarios autenticados
--    (el admin necesita poder UPDATE forzar_cierre en filas de OTROS usuarios;
--     si solo pueden tocar su propia fila, el botón "Cerrar sesión" falla)

create policy "sesiones authenticated all"
  on public.sesiones_activas
  for all
  to authenticated
  using (true)
  with check (true);

-- 5) (Opcional) Publicar en Realtime para cierre inmediato
--    En Dashboard → Database → Replication → sesiones_activas → habilitar
--    O por SQL (si tienes permiso):
-- alter publication supabase_realtime add table public.sesiones_activas;

-- Verificación rápida:
-- select * from public.sesiones_activas;
-- update public.sesiones_activas set forzar_cierre = true where id = 'algun_id';
