-- ============================================================
-- LocoFly — Supabase Database Setup
-- ============================================================
-- HOW TO RUN THIS:
--   1. Go to your Supabase project → SQL Editor (left sidebar)
--   2. Click "New query"
--   3. Paste this entire file and click "Run"
--
-- This creates all 10 tables, their relationships (foreign keys),
-- Row Level Security policies (so users only see their own data),
-- and helper indexes for fast queries.
-- ============================================================


-- ─── Enable UUID extension ─────────────────────────────────────────────────
-- Supabase uses UUIDs for user IDs. This extension provides gen_random_uuid()
-- which auto-generates unique IDs.
create extension if not exists "uuid-ossp";


-- ─── USERS table ──────────────────────────────────────────────────────────
-- Note: We do NOT store passwords here. Supabase Auth handles passwords
-- in its own internal auth.users table. This table stores extra profile info.
create table public.users (
  id               uuid primary key default gen_random_uuid(),
  full_name        text,
  email            text unique not null,
  phone            text,
  auth_id          uuid references auth.users(id) on delete cascade,
  profile_photo_url text,
  current_city     text,
  created_at       timestamptz default now()
);

-- Row Level Security (RLS): users can only read/update their own row
alter table public.users enable row level security;

create policy "Users can view own profile"
  on public.users for select
  using (auth.uid() = auth_id);

create policy "Users can update own profile"
  on public.users for update
  using (auth.uid() = auth_id);

-- Automatically create a users row when someone signs up via Supabase Auth
-- This is a database trigger — it fires automatically on new auth signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (auth_id, email, full_name)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name'  -- from signup metadata
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


-- ─── AIRCRAFT table ───────────────────────────────────────────────────────
create table public.aircraft (
  id                   bigint generated always as identity primary key,
  name                 text not null,
  type                 text not null,
  airline              text not null,
  flight_number        text not null,
  passengers_capacity  int not null,
  range_km             int not null,
  amenities            jsonb default '[]',   -- e.g. ["WiFi", "Catering", "Bar"]
  charter_benefits     jsonb default '[]',
  images               text[] default '{}',  -- Array of storage URLs
  created_at           timestamptz default now()
);

-- Aircraft is public — anyone (logged in) can view aircraft details
alter table public.aircraft enable row level security;
create policy "Aircraft is viewable by authenticated users"
  on public.aircraft for select
  to authenticated
  using (true);


-- ─── FLIGHTS table ────────────────────────────────────────────────────────
create table public.flights (
  id               bigint generated always as identity primary key,
  aircraft_id      bigint references public.aircraft(id) not null,
  from_city        text not null,
  from_code        text not null,
  from_latlng      point,             -- for map view and nearby search
  to_city          text not null,
  to_code          text not null,
  to_latlng        point,
  departure_time   timestamptz not null,
  arrival_time     timestamptz not null,
  duration_mins    int not null,
  distance_km      int not null,
  market_price     numeric(12,2) not null,
  status           text not null default 'available'
                   check (status in ('available', 'closed', 'completed')),
  created_at       timestamptz default now()
);

alter table public.flights enable row level security;
create policy "Flights are viewable by authenticated users"
  on public.flights for select
  to authenticated
  using (true);

-- Index for filtering by status — we almost always filter by 'available'
create index idx_flights_status on public.flights(status);
create index idx_flights_departure on public.flights(departure_time);


-- ─── SPECIAL_OFFERS table ─────────────────────────────────────────────────
create table public.special_offers (
  id               bigint generated always as identity primary key,
  flight_id        bigint references public.flights(id) not null,
  title            text not null,
  description      text,
  offer_price      numeric(12,2) not null,
  discount_percent int not null default 0,
  valid_until      timestamptz not null,
  created_at       timestamptz default now()
);

alter table public.special_offers enable row level security;
create policy "Special offers viewable by authenticated users"
  on public.special_offers for select
  to authenticated
  using (true);


-- ─── BIDS table ───────────────────────────────────────────────────────────
create table public.bids (
  id               bigint generated always as identity primary key,
  user_id          uuid references public.users(id) not null,
  flight_id        bigint references public.flights(id) not null,
  bid_amount       numeric(12,2) not null,
  advance_paid     numeric(12,2) not null default 0,
  charter_option   text not null,
  status           text not null default 'pending'
                   check (status in ('pending', 'accepted', 'rejected', 'cancelled', 'expired')),
  expires_at       timestamptz not null,
  cancel_reason    text,
  created_at       timestamptz default now()
);

alter table public.bids enable row level security;

create policy "Users can view own bids"
  on public.bids for select
  using (
    user_id = (select id from public.users where auth_id = auth.uid())
  );

create policy "Users can insert own bids"
  on public.bids for insert
  with check (
    user_id = (select id from public.users where auth_id = auth.uid())
  );

create index idx_bids_user_id on public.bids(user_id);
create index idx_bids_flight_id on public.bids(flight_id);
create index idx_bids_status on public.bids(status);


-- ─── BOOKINGS table ───────────────────────────────────────────────────────
create table public.bookings (
  id                  bigint generated always as identity primary key,
  bid_id              bigint references public.bids(id) not null,
  user_id             uuid references public.users(id) not null,
  flight_id           bigint references public.flights(id) not null,
  booking_reference   text unique not null,
  charter_option      text not null,
  total_amount        numeric(12,2) not null,
  taxes               numeric(12,2) not null default 0,
  discount            numeric(12,2) not null default 0,
  eticket_url         text,
  status              text not null default 'confirmed'
                      check (status in ('confirmed', 'cancelled', 'completed')),
  created_at          timestamptz default now()
);

alter table public.bookings enable row level security;

create policy "Users can view own bookings"
  on public.bookings for select
  using (
    user_id = (select id from public.users where auth_id = auth.uid())
  );

create index idx_bookings_user_id on public.bookings(user_id);


-- ─── PASSENGERS table ─────────────────────────────────────────────────────
create table public.passengers (
  id               bigint generated always as identity primary key,
  booking_id       bigint references public.bookings(id) not null,
  user_id          uuid references public.users(id) not null,
  full_name        text not null,
  email            text not null,
  phone            text not null,
  dob              date,
  aadhaar          text,
  passport_number  text,
  passport_url     text,
  created_at       timestamptz default now()
);

alter table public.passengers enable row level security;

create policy "Users can view own passengers"
  on public.passengers for select
  using (
    user_id = (select id from public.users where auth_id = auth.uid())
  );

create policy "Users can insert passengers for own bookings"
  on public.passengers for insert
  with check (
    user_id = (select id from public.users where auth_id = auth.uid())
  );

create policy "Users can update own passengers"
  on public.passengers for update
  using (
    user_id = (select id from public.users where auth_id = auth.uid())
  );


-- ─── PAYMENTS table ───────────────────────────────────────────────────────
create table public.payments (
  id                    bigint generated always as identity primary key,
  booking_id            bigint references public.bookings(id),
  user_id               uuid references public.users(id) not null,
  amount                numeric(12,2) not null,
  type                  text not null check (type in ('advance', 'full', 'refund')),
  method                text check (method in ('card', 'upi', 'netbanking', 'wallet')),
  razorpay_order_id     text,
  razorpay_payment_id   text,
  razorpay_refund_id    text,
  status                text not null default 'pending'
                        check (status in ('pending', 'success', 'failed', 'refunded')),
  created_at            timestamptz default now()
);

alter table public.payments enable row level security;

create policy "Users can view own payments"
  on public.payments for select
  using (
    user_id = (select id from public.users where auth_id = auth.uid())
  );

create index idx_payments_user_id on public.payments(user_id);


-- ─── NOTIFICATIONS table ──────────────────────────────────────────────────
create table public.notifications (
  id          bigint generated always as identity primary key,
  user_id     uuid references public.users(id) not null,
  booking_id  bigint references public.bookings(id),
  type        text not null
              check (type in ('bid_accepted', 'bid_rejected', 'outbid', 'booking_confirmed')),
  message     text not null,
  is_read     boolean not null default false,
  created_at  timestamptz default now()
);

alter table public.notifications enable row level security;

create policy "Users can view own notifications"
  on public.notifications for select
  using (
    user_id = (select id from public.users where auth_id = auth.uid())
  );

create policy "Users can update own notifications (mark as read)"
  on public.notifications for update
  using (
    user_id = (select id from public.users where auth_id = auth.uid())
  );

create index idx_notifications_user_id on public.notifications(user_id);
create index idx_notifications_is_read on public.notifications(is_read);


-- ─── Storage buckets ──────────────────────────────────────────────────────
-- Run these separately in the Supabase Storage section, or via SQL:
insert into storage.buckets (id, name, public) values ('profile-photos', 'profile-photos', true);
insert into storage.buckets (id, name, public) values ('aircraft-images', 'aircraft-images', true);
insert into storage.buckets (id, name, public) values ('passports', 'passports', false);      -- private!
insert into storage.buckets (id, name, public) values ('etickets', 'etickets', false);         -- private!

-- Storage policies
create policy "Anyone can view aircraft images"
  on storage.objects for select
  using ( bucket_id = 'aircraft-images' );

create policy "Anyone can view profile photos"
  on storage.objects for select
  using ( bucket_id = 'profile-photos' );

create policy "Users can upload their own profile photo"
  on storage.objects for insert
  with check (
    bucket_id = 'profile-photos' and
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- ─── Sample data (optional — helps you test the app) ─────────────────────
-- Insert one aircraft and one flight so the app has something to show
insert into public.aircraft (name, type, airline, flight_number, passengers_capacity, range_km, amenities, charter_benefits, images)
values (
  'Bombardier Global 6000',
  'Bombardier Global 6000',
  'Elite Aviation India',
  'EA-101',
  14,
  10000,
  '["In-flight WiFi", "Power Outlets", "Entertainment", "Climate Control", "Full Catering", "Bar & Beverages"]',
  '["Dedicated Crew", "Lounge Access", "Priority Boarding", "Custom Menu"]',
  '{}'
);

insert into public.flights (aircraft_id, from_city, from_code, to_city, to_code, departure_time, arrival_time, duration_mins, distance_km, market_price, status)
values (
  1,
  'Bangalore', 'BLR',
  'Delhi', 'DEL',
  now() + interval '2 days' + interval '14 hours 30 minutes',
  now() + interval '2 days' + interval '17 hours',
  150,
  1740,
  215999,
  'available'
);

-- ============================================================
-- Done! Your database is ready.
-- Next step: go back to the Flutter app and add your
-- Supabase URL and anon key to app_constants.dart
-- ============================================================
