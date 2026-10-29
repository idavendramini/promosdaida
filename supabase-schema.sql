-- PROMOSDAIDA: estrutura inicial do banco de dados (Supabase/Postgres)
-- Execute no SQL Editor do seu projeto Supabase.
-- Acesso público somente a publicações publicadas; gerenciamento via usuário autenticado.

create extension if not exists pgcrypto;

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  slug text unique,
  category text not null default 'Achadinhos gerais',
  description text not null default '',
  cover_image_url text,
  published boolean not null default true,
  published_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  name text not null,
  description text not null default '',
  image_url text,
  affiliate_url text not null,
  position integer not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists posts_published_date_idx
  on public.posts (published, published_at desc);
create index if not exists products_post_position_idx
  on public.products (post_id, position);

alter table public.posts enable row level security;
alter table public.products enable row level security;

-- Visitantes podem ler apenas publicações publicadas e produtos pertencentes a elas.
drop policy if exists "Public can read published posts" on public.posts;
create policy "Public can read published posts"
  on public.posts for select
  using (published = true);

drop policy if exists "Public can read products for published posts" on public.products;
create policy "Public can read products for published posts"
  on public.products for select
  using (exists (
    select 1 from public.posts
    where posts.id = products.post_id and posts.published = true
  ));

-- Painel: qualquer usuário autenticado pode administrar conteúdo.
-- Para produção, restrinja o acesso a uma conta de administradora usando uma tabela/claim de função.
drop policy if exists "Authenticated users manage posts" on public.posts;
create policy "Authenticated users manage posts"
  on public.posts for all to authenticated
  using (true) with check (true);

drop policy if exists "Authenticated users manage products" on public.products;
create policy "Authenticated users manage products"
  on public.products for all to authenticated
  using (true) with check (true);

grant select on public.posts, public.products to anon;
grant select, insert, update, delete on public.posts, public.products to authenticated;
