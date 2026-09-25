-- Phase 2 RLS: business_hours, services, staff, staff_services, staff_schedules

alter table business_hours enable row level security;
create policy business_hours_owner_manage on business_hours
  for all using (owns_business(business_id) or is_admin())
  with check (owns_business(business_id) or is_admin());
create policy business_hours_public_read on business_hours
  for select using (
    exists (select 1 from businesses b where b.id = business_id and b.status = 'approved')
  );

alter table services enable row level security;
create policy services_owner_manage on services
  for all using (owns_business(business_id) or is_admin())
  with check (owns_business(business_id) or is_admin());
create policy services_public_read on services
  for select using (
    active = true
    and exists (select 1 from businesses b where b.id = business_id and b.status = 'approved')
  );

alter table staff enable row level security;
create policy staff_owner_manage on staff
  for all using (owns_business(business_id) or is_admin())
  with check (owns_business(business_id) or is_admin());
create policy staff_public_read on staff
  for select using (
    active = true
    and exists (select 1 from businesses b where b.id = business_id and b.status = 'approved')
  );

alter table staff_services enable row level security;
create policy staff_services_owner_manage on staff_services
  for all using (
    exists (select 1 from staff s where s.id = staff_id and owns_business(s.business_id))
    or is_admin()
  )
  with check (
    exists (select 1 from staff s where s.id = staff_id and owns_business(s.business_id))
    or is_admin()
  );
create policy staff_services_public_read on staff_services
  for select using (
    exists (
      select 1 from staff s join businesses b on b.id = s.business_id
      where s.id = staff_id and b.status = 'approved'
    )
  );

alter table staff_schedules enable row level security;
create policy staff_schedules_owner_manage on staff_schedules
  for all using (
    exists (select 1 from staff s where s.id = staff_id and owns_business(s.business_id))
    or is_admin()
  )
  with check (
    exists (select 1 from staff s where s.id = staff_id and owns_business(s.business_id))
    or is_admin()
  );
create policy staff_schedules_public_read on staff_schedules
  for select using (
    exists (
      select 1 from staff s join businesses b on b.id = s.business_id
      where s.id = staff_id and b.status = 'approved'
    )
  );
