-- BarberHub NG — Phase 1: core schema
create extension if not exists "pgcrypto";

create type user_role as enum ('customer','barber','admin');
create type business_status as enum ('pending','approved','suspended','rejected');
create type booking_status as enum ('pending','confirmed','completed','cancelled','no_show','rescheduled');
create type payment_status as enum ('unpaid','deposit_paid','paid','refunded','failed');

-- profiles: one row per Supabase auth user
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  avatar_url text,
  role user_role not null default 'customer',
  created_at timestamptz not null default now()
);

create table businesses (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  name text not null,
  slug text unique not null,
  description text,
  logo_url text,
  cover_url text,
  whatsapp_number text,
  phone text,
  email text,
  city text,
  status business_status not null default 'pending',
  verified boolean not null default false,
  created_at timestamptz not null default now()
);
create index idx_businesses_city on businesses(city);
create index idx_businesses_status on businesses(status);

create table business_locations (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id) on delete cascade,
  address_line text,
  city text,
  state text,
  lat numeric,
  lng numeric,
  is_primary boolean not null default true
);

create table business_hours (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id) on delete cascade,
  day_of_week smallint not null check (day_of_week between 0 and 6),
  open_time time,
  close_time time,
  is_closed boolean not null default false,
  unique(business_id, day_of_week)
);

create table service_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null
);

create table services (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id) on delete cascade,
  category_id uuid references service_categories(id),
  name text not null,
  description text,
  price numeric(10,2) not null,
  duration_minutes int not null,
  image_url text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create index idx_services_business on services(business_id);

create table staff (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id) on delete cascade,
  profile_id uuid references profiles(id),
  name text not null,
  photo_url text,
  bio text,
  phone text,
  role text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create index idx_staff_business on staff(business_id);

create table staff_services (
  staff_id uuid not null references staff(id) on delete cascade,
  service_id uuid not null references services(id) on delete cascade,
  primary key (staff_id, service_id)
);

create table staff_schedules (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid not null references staff(id) on delete cascade,
  day_of_week smallint not null check (day_of_week between 0 and 6),
  start_time time,
  end_time time,
  break_start time,
  break_end time,
  is_day_off boolean not null default false
);

create table customers (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id) on delete cascade,
  profile_id uuid references profiles(id),
  full_name text not null,
  phone text,
  email text,
  photo_url text,
  total_visits int not null default 0,
  total_spent numeric(10,2) not null default 0,
  last_visit date,
  preferred_staff_id uuid references staff(id),
  created_at timestamptz not null default now()
);
create index idx_customers_business on customers(business_id);

create table customer_notes (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references customers(id) on delete cascade,
  business_id uuid not null references businesses(id) on delete cascade,
  note text not null,
  created_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

create table appointments (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id),
  staff_id uuid not null references staff(id),
  service_id uuid not null references services(id),
  customer_id uuid not null references customers(id),
  profile_id uuid references profiles(id),
  start_time timestamptz not null,
  end_time timestamptz not null,
  status booking_status not null default 'pending',
  payment_status payment_status not null default 'unpaid',
  total_price numeric(10,2) not null,
  deposit_amount numeric(10,2) not null default 0,
  notes text,
  created_at timestamptz not null default now()
);
create index idx_appt_business_time on appointments(business_id, start_time);
create index idx_appt_staff_time on appointments(staff_id, start_time);

create table appointment_status_history (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null references appointments(id) on delete cascade,
  old_status booking_status,
  new_status booking_status not null,
  changed_by uuid references profiles(id),
  changed_at timestamptz not null default now()
);

create table payments (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null references appointments(id),
  amount numeric(10,2) not null,
  type text not null check (type in ('deposit','full')),
  status payment_status not null default 'unpaid',
  paystack_reference text unique,
  created_at timestamptz not null default now()
);

create table payment_transactions (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references payments(id) on delete cascade,
  raw_response jsonb,
  verified_at timestamptz,
  created_at timestamptz not null default now()
);

create table refunds (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references payments(id),
  amount numeric(10,2) not null,
  reason text,
  status text not null default 'pending',
  processed_at timestamptz,
  created_at timestamptz not null default now()
);

create table reviews (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid unique not null references appointments(id),
  business_id uuid not null references businesses(id),
  profile_id uuid not null references profiles(id),
  rating smallint not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now()
);
create index idx_reviews_business on reviews(business_id);

create table review_replies (
  id uuid primary key default gen_random_uuid(),
  review_id uuid unique not null references reviews(id) on delete cascade,
  business_id uuid not null references businesses(id),
  reply text not null,
  created_at timestamptz not null default now()
);

create table gallery (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id) on delete cascade,
  image_url text not null,
  caption text,
  created_at timestamptz not null default now()
);

create table favorites (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  business_id uuid not null references businesses(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(profile_id, business_id)
);

create table notifications (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  type text not null,
  title text not null,
  body text,
  related_appointment_id uuid references appointments(id),
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table conversations (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id),
  customer_profile_id uuid not null references profiles(id),
  created_at timestamptz not null default now()
);

create table messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references conversations(id) on delete cascade,
  sender_id uuid not null references profiles(id),
  body text not null,
  created_at timestamptz not null default now()
);

create table audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references profiles(id),
  action text not null,
  target_table text,
  target_id uuid,
  details jsonb,
  created_at timestamptz not null default now()
);

-- auto-create a profile row whenever someone signs up
create or replace function handle_new_user()
returns trigger as $$
begin
  insert into profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce((new.raw_user_meta_data->>'role')::user_role, 'customer')
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();
