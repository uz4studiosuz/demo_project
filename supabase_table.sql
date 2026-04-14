-- 1. APP_USERS — Jadvallar
CREATE TABLE IF NOT EXISTS public.app_users (
  id               BIGSERIAL PRIMARY KEY,
  branch_id        BIGINT,
  district_id      BIGINT,
  first_name       TEXT NOT NULL,
  last_name        TEXT NOT NULL,
  middle_name      TEXT,
  phone            TEXT,
  username         TEXT NOT NULL UNIQUE,
  password_hash    TEXT NOT NULL,
  role             TEXT NOT NULL CHECK (role IN ('SURVEYOR', 'DRIVER', 'ADMIN')),
  is_active        BOOLEAN NOT NULL DEFAULT TRUE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Demo foydalanuvchilar
INSERT INTO public.app_users (first_name, last_name, username, password_hash, role)
VALUES
  ('Ali',    'Valiyev',   'surveyor1', '1234', 'SURVEYOR'),
  ('Bobur',  'Toshmatov', 'surveyor2', '1234', 'SURVEYOR'),
  ('Jasur',  'Rahimov',   'driver1',   '1234', 'DRIVER'),
  ('Dilnoza','Karimova',  'driver2',   '1234', 'DRIVER')
ON CONFLICT (username) DO NOTHING;

-- 2. HOUSEHOLDS — Xonadonlar
CREATE TABLE IF NOT EXISTS public.households (
  id                    BIGSERIAL PRIMARY KEY,
  region_id             BIGINT NOT NULL DEFAULT 1,
  district_id           BIGINT NOT NULL DEFAULT 1,
  branch_id             BIGINT,
  created_by_agent_id   BIGINT NOT NULL DEFAULT 1,
  cadastral_number      TEXT,
  official_address      TEXT NOT NULL,
  house_number          TEXT,
  apartment             TEXT,
  landmark              TEXT,
  latitude              DOUBLE PRECISION NOT NULL DEFAULT 40.3834,
  longitude             DOUBLE PRECISION NOT NULL DEFAULT 71.7864,
  is_verified           BOOLEAN NOT NULL DEFAULT FALSE,
  is_active             BOOLEAN NOT NULL DEFAULT TRUE,
  tuman_name            TEXT,
  qfy_name              TEXT,
  mfy_name              TEXT,
  street_name           TEXT,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Yangi ustunlarni qo'shish (Xonadon/Kvartira uchun)
ALTER TABLE public.households
  ADD COLUMN IF NOT EXISTS property_type   TEXT NOT NULL DEFAULT 'HOUSE' CHECK (property_type IN ('HOUSE', 'APARTMENT')),
  ADD COLUMN IF NOT EXISTS building_number TEXT,
  ADD COLUMN IF NOT EXISTS floor           INT;

-- 3. RESIDENTS — Aholi
CREATE TABLE IF NOT EXISTS public.residents (
  id               BIGSERIAL PRIMARY KEY,
  household_id     BIGINT NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
  first_name       TEXT NOT NULL,
  last_name        TEXT NOT NULL,
  middle_name      TEXT,
  full_name        TEXT,
  phone_primary    TEXT,
  phone_secondary  TEXT,
  birth_date       DATE,
  gender           TEXT NOT NULL DEFAULT 'UNKNOWN' CHECK (gender IN ('MALE', 'FEMALE', 'UNKNOWN')),
  role             TEXT,
  is_active        BOOLEAN NOT NULL DEFAULT TRUE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indekslar
CREATE INDEX IF NOT EXISTS idx_residents_household ON public.residents(household_id);
CREATE INDEX IF NOT EXISTS idx_households_active   ON public.households(is_active);

-- 4. RLS va POLICIES (O'chirish va qayta yaratish)
ALTER TABLE public.app_users   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.households  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.residents   ENABLE ROW LEVEL SECURITY;

-- Eski ruxsatlarni o'chirish (Agar mavjud bo'lsa)
DROP POLICY IF EXISTS "allow_read_app_users"  ON public.app_users;
DROP POLICY IF EXISTS "allow_all_households"  ON public.households;
DROP POLICY IF EXISTS "allow_all_residents"   ON public.residents;

-- Yangi ruxsatlarni yaratish
CREATE POLICY "allow_read_app_users"  ON public.app_users  FOR SELECT USING (true);
CREATE POLICY "allow_all_households"  ON public.households FOR ALL    USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_residents"   ON public.residents  FOR ALL    USING (true) WITH CHECK (true);