alter table customers enable row level security;
create policy customers_public_insert on customers
  for insert with check (true);
create policy customers_read on customers
  for select using (true);
create policy customers_owner_business_manage on customers
  for update using (owns_business(business_id) or is_admin());

alter table appointments enable row level security;
create policy appointments_public_insert on appointments
  for insert with check (true);
create policy appointments_read on appointments
  for select using (
    profile_id = auth.uid()
    or owns_business(business_id)
    or is_admin()
  );
create policy appointments_owner_update on appointments
  for update using (owns_business(business_id) or is_admin());
