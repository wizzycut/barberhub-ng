create or replace function get_available_slots(
  p_business_id uuid,
  p_staff_id uuid,
  p_service_id uuid,
  p_date date
)
returns table(slot_time timestamptz) as $$
declare
  v_duration int;
  v_day_of_week int;
  v_open_time time;
  v_close_time time;
  v_is_closed boolean;
  v_tz text := 'Africa/Lagos';
begin
  select duration_minutes into v_duration from services where id = p_service_id;

  v_day_of_week := extract(dow from p_date);

  select open_time, close_time, is_closed
  into v_open_time, v_close_time, v_is_closed
  from business_hours
  where business_id = p_business_id and day_of_week = v_day_of_week;

  if v_is_closed is null or v_is_closed = true or v_open_time is null then
    return;
  end if;

  return query
  with slots as (
    select generate_series(
      (p_date::timestamp + v_open_time) at time zone v_tz,
      (p_date::timestamp + v_close_time) at time zone v_tz - (v_duration || ' minutes')::interval,
      '15 minutes'::interval
    ) as slot_start
  )
  select slot_start
  from slots
  where not exists (
    select 1 from appointments a
    where a.staff_id = p_staff_id
      and a.status not in ('cancelled', 'no_show')
      and (slot_start, slot_start + (v_duration || ' minutes')::interval)
          overlaps (a.start_time, a.end_time)
  )
  order by slot_start;
end;
$$ language plpgsql stable;
