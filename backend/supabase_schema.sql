-- MARCHBOUND online persistence draft.
-- NOT wired into MVP yet. Sensitive mutations should eventually be server-authoritative.

create extension if not exists "pgcrypto";

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Warden',
  level integer not null default 1,
  xp bigint not null default 0,
  renown bigint not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists settlements (
  user_id uuid primary key references profiles(id) on delete cascade,
  name text not null default 'Dawnkeep',
  world_seed bigint not null,
  season integer not null default 1,
  updated_at timestamptz not null default now()
);

create table if not exists player_resources (
  user_id uuid primary key references profiles(id) on delete cascade,
  gold numeric not null default 0,
  wood numeric not null default 0,
  stone numeric not null default 0,
  iron numeric not null default 0,
  food numeric not null default 0,
  mana numeric not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists item_instances (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  template_id text not null,
  slot text not null,
  rarity text not null,
  power integer not null,
  upgrade integer not null default 0,
  tradable boolean not null default true,
  equipped boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists market_listings (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references profiles(id) on delete cascade,
  item_id uuid not null unique references item_instances(id) on delete cascade,
  price_gold bigint not null check (price_gold > 0),
  status text not null default 'active',
  created_at timestamptz not null default now()
);

alter table profiles enable row level security;
alter table settlements enable row level security;
alter table player_resources enable row level security;
alter table item_instances enable row level security;
alter table market_listings enable row level security;

create policy "profile own read/write" on profiles for all using (auth.uid() = id) with check (auth.uid() = id);
create policy "settlement own read/write" on settlements for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "resources own read" on player_resources for select using (auth.uid() = user_id);
create policy "items own read" on item_instances for select using (auth.uid() = owner_id);

-- Marketplace public visibility can be widened later, but purchases and scarce
-- economy mutations should be performed by trusted server functions/API.
