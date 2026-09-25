-- Phase 1 RLS: profiles + businesses only.
-- Services/staff/appointments/etc. get their policies in later phases
-- as those features are built, so each phase stays testable on its own.

create or replace function is_admin()
returns boolean as $$
  select exists (
    select 1 from profiles where id = auth.uid() and role = 'admin'
  );
$$ language sql security definer stable;

create or replace function owns_business(target_business_id uuid)
returns boolean as $$
  select exists (
    select 1 from businesses
    where id = target_business_id and owner_id = auth.uid()
  );
$$ language sql security definer stable;

alter table profiles enable row level security;
create policy profiles_select_own on profiles
  for select using (id = auth.uid() or is_admin());
create policy profiles_update_own on profiles
  for update using (id = auth.uid());

alter table businesses enable row level security;
create policy businesses_public_read on businesses
  for select using (status = 'approved' or owner_id = auth.uid() or is_admin());
create policy businesses_owner_insert on businesses
  for insert with check (owner_id = auth.uid());
create policy businesses_owner_update on businesses
  for update using (owner_id = auth.uid() or is_admin());
