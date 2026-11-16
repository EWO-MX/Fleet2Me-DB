-- ══════════════════════════════════════════════════════
--  GPS Tracking — Fleet2Me
--  Tablas: gps_settings, vehicle_locations
-- ══════════════════════════════════════════════════════

-- 1. Configuración GPS por empresa
CREATE TABLE IF NOT EXISTS public.gps_settings (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id    uuid NOT NULL UNIQUE REFERENCES public.companies(id) ON DELETE CASCADE,
  enabled       boolean NOT NULL DEFAULT false,
  mode          text NOT NULL DEFAULT 'interval'
                  CHECK (mode IN ('realtime','interval','last_only')),
  interval_min  integer NOT NULL DEFAULT 10
                  CHECK (interval_min IN (1,5,10,15,30)),
  track_route   boolean NOT NULL DEFAULT true,
  retention_days integer NOT NULL DEFAULT 30
                  CHECK (retention_days IN (7,15,30,90)),
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

-- 2. Registros de posición GPS
CREATE TABLE IF NOT EXISTS public.vehicle_locations (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  vehicle_id      text NOT NULL,
  driver_user_id  text,
  lat             double precision NOT NULL,
  lng             double precision NOT NULL,
  speed_kmh       real,
  accuracy_m      real,
  recorded_at     timestamptz NOT NULL DEFAULT now(),
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_vehicle_locations_company    ON public.vehicle_locations(company_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_locations_vehicle    ON public.vehicle_locations(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_locations_recorded   ON public.vehicle_locations(recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_vehicle_locations_latest     ON public.vehicle_locations(company_id, vehicle_id, recorded_at DESC);

-- RLS gps_settings
ALTER TABLE public.gps_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "gps_settings_select" ON public.gps_settings
  FOR SELECT USING (
    company_id::text IN (
      SELECT company_id::text FROM public.users
      WHERE auth_user_id::text = auth.uid()::text
    )
  );

CREATE POLICY "gps_settings_insert" ON public.gps_settings
  FOR INSERT WITH CHECK (
    company_id::text IN (
      SELECT company_id::text FROM public.users
      WHERE auth_user_id::text = auth.uid()::text
    )
  );

CREATE POLICY "gps_settings_update" ON public.gps_settings
  FOR UPDATE USING (
    company_id::text IN (
      SELECT company_id::text FROM public.users
      WHERE auth_user_id::text = auth.uid()::text
    )
  );

-- RLS vehicle_locations
ALTER TABLE public.vehicle_locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "vehicle_locations_select" ON public.vehicle_locations
  FOR SELECT USING (
    company_id::text IN (
      SELECT company_id::text FROM public.users
      WHERE auth_user_id::text = auth.uid()::text
    )
  );

CREATE POLICY "vehicle_locations_insert" ON public.vehicle_locations
  FOR INSERT WITH CHECK (
    company_id::text IN (
      SELECT company_id::text FROM public.users
      WHERE auth_user_id::text = auth.uid()::text
    )
  );
