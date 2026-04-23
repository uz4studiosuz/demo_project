-- 0. CLEANUP — Eski jadvallarni o'chirish (Toza o'rnatish uchun)
DROP TABLE IF EXISTS public.residents CASCADE;
DROP TABLE IF EXISTS public.households CASCADE;
DROP TABLE IF EXISTS public.app_users CASCADE;
DROP TABLE IF EXISTS public.streets CASCADE;
DROP TABLE IF EXISTS public.neighborhoods CASCADE;
DROP TABLE IF EXISTS public.districts CASCADE;

-- 1. GEOGRAPHY — Hududlar va Manzillar
CREATE TABLE public.districts (
  id          SERIAL PRIMARY KEY,
  name        TEXT NOT NULL UNIQUE,
  is_city     BOOLEAN DEFAULT false
);

CREATE TABLE public.neighborhoods (
  id          SERIAL PRIMARY KEY,
  district_id INTEGER REFERENCES public.districts(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  UNIQUE(district_id, name)
);

CREATE TABLE public.streets (
  id              SERIAL PRIMARY KEY,
  neighborhood_id INTEGER REFERENCES public.neighborhoods(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  UNIQUE(neighborhood_id, name)
);

-- Seed Data: Districts (Tumanlar va Shaharlar)
INSERT INTO public.districts (id, name, is_city) VALUES
  (1,  'Farg''ona sh.',       true),
  (2,  'Marg''ilon sh.',      true),
  (3,  'Qo''qon sh.',         true),
  (4,  'Quvasoy sh.',        true),
  (5,  'O''zbekiston tumani', false),
  (6,  'Farg''ona tumani',    false),
  (7,  'Rishton tumani',     false),
  (8,  'Quva tumani',        false),
  (9,  'Toshloq tumani',     false),
  (10, 'Oltiariq tumani',    false),
  (11, 'Beshariq tumani',    false),
  (12, 'Bog''dod tumani',     false),
  (13, 'Dang''ara tumani',    false),
  (14, 'Qo''shtepa tumani',   false),
  (15, 'So''x tumani',        false),
  (16, 'Uchko''prik tumani',  false),
  (17, 'Yozyovon tumani',    false)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, is_city = EXCLUDED.is_city;

-- Seed Data: Neighborhoods (MFY lar)
INSERT INTO public.neighborhoods (district_id, name) VALUES
  -- Farg'ona sh. (1)
  (1, 'Bag''ishamol MFY'), (1, 'Bahor MFY'), (1, 'Darvozaqo''rg''on MFY'), (1, 'Do''stlik MFY'), (1, 'Fayz MFY'), (1, 'G''alaba MFY'), 
  (1, 'Guliston MFY'), (1, 'Hamkor MFY'), (1, 'Istiqbol MFY'), (1, 'Kirgili MFY'), (1, 'Ko''hna shahar MFY'), (1, 'Marifat MFY'), 
  (1, 'Milliy bog'' MFY'), (1, 'Mustaqillik MFY'), (1, 'Navoiy MFY'), (1, 'Navro''z MFY'), (1, 'Niyozbekhoja MFY'), (1, 'Oydin MFY'), 
  (1, 'Sarbon MFY'), (1, 'Tinchlik MFY'), (1, 'To''ytepa MFY'), (1, 'Uychi MFY'), (1, 'Vodil MFY'), (1, 'Yangi Farg''ona MFY'), 
  (1, 'Yangi hayot MFY'), (1, 'Yashillik MFY'),
  -- Marg'ilon sh. (2)
  (2, 'Asaka MFY'), (2, 'Atlas MFY'), (2, 'Bog''boqcha MFY'), (2, 'Bogiston MFY'), (2, 'Chilonzor MFY'), (2, 'Guliston MFY'), 
  (2, 'Hamza MFY'), (2, 'Hisor MFY'), (2, 'Markaziy MFY'), (2, 'Mustaqillik MFY'), (2, 'Navro''z MFY'), (2, 'Pahlavon MFY'), 
  (2, 'Rizma MFY'), (2, 'Soliqo''rg''on MFY'), (2, 'Yangiariq MFY'), (2, 'Yipak yo''li MFY'),
  -- Qo'qon sh. (3)
  (3, 'Bog''ishamol MFY'), (3, 'Do''stlik MFY'), (3, 'G''ovsar MFY'), (3, 'Guliston MFY'), (3, 'Istiqbol MFY'), (3, 'Ko''kdala MFY'), 
  (3, 'Markaziy MFY'), (3, 'Mustakillik MFY'), (3, 'Navoiy MFY'), (3, 'Uchko''prik MFY'), (3, 'Yangi hayot MFY'),
  -- Quvasoy sh. (4)
  (4, 'Chimyon MFY'), (4, 'Do''stlik MFY'), (4, 'Markaziy MFY'), (4, 'Navro''z MFY'), (4, 'Tinchlik MFY'), (4, 'Yangi MFY'),
  -- Farg'ona tumani (6)
  (6, 'Axunboboev MFY'), (6, 'Bog''dod MFY'), (6, 'Daminobod MFY'), (6, 'Evchi MFY'), (6, 'Janubiy MFY'), (6, 'Kuyibozor MFY'), 
  (6, 'Mindon MFY'), (6, 'Mustakillik MFY'), (6, 'Poytovvoq MFY'), (6, 'Sarbon MFY'), (6, 'Shoximardon MFY'), (6, 'Vodil MFY'), (6, 'Yangiobod MFY'),
  -- O'zbekiston tumani (5)
  (5, 'Bo''ston MFY'), (5, 'G''ulomlar MFY'), (5, 'Ittifoq MFY'), (5, 'Mehnat MFY'), (5, 'Mustaqillik MFY'), (5, 'Navoiy MFY'), 
  (5, 'Nursux MFY'), (5, 'Qudash MFY'), (5, 'Sho''rsuv MFY'), (5, 'Tinchlik MFY'), (5, 'Yakkatut MFY'),
  -- Rishton tumani (7)
  (7, 'Buloqboshi MFY'), (7, 'Do''stlik MFY'), (7, 'Istiqlol MFY'), (7, 'Kulolchilar MFY'), (7, 'Markaziy MFY'), (7, 'Navro''z MFY'), 
  (7, 'Oqmachit MFY'), (7, 'Oqyer MFY'), (7, 'Zohidon MFY'),
  -- Quva tumani (8)
  (8, 'Bahor MFY'), (8, 'G''alaba MFY'), (8, 'Ko''rg''oncha MFY'), (8, 'Markaz MFY'), (8, 'Pastxalfa MFY'), (8, 'Qoraqum MFY'), 
  (8, 'Tinchlik MFY'), (8, 'Tolmozor MFY'),
  -- Toshloq tumani (9)
  (9, 'Bo''ston MFY'), (9, 'Do''stlik MFY'), (9, 'Nayman MFY'), (9, 'Sadda MFY'), (9, 'Tinchlik MFY'), (9, 'Zarkent MFY'),
  -- Oltiariq tumani (10)
  (10, 'Azizbek MFY'), (10, 'Bog''li MFY'), (10, 'Do''stlik MFY'), (10, 'Guliston MFY'), (10, 'Mustaqillik MFY'), (10, 'Tinchlik MFY'),
  -- Beshariq tumani (11)
  (11, 'Baxt MFY'), (11, 'Gulshan MFY'), (11, 'Mehribon MFY'), (11, 'Mustaqillik MFY'), (11, 'Obod MFY'), (11, 'Tinchlik MFY'),
  -- Bog'dod tumani (12)
  (12, 'Do''stlik MFY'), (12, 'G''alaba MFY'), (12, 'Markaziy MFY'), (12, 'Navro''z MFY'), (12, 'Yangi hayot MFY'),
  -- Dang'ara tumani (13)
  (13, 'Bog''iston MFY'), (13, 'Do''stlik MFY'), (13, 'Markaziy MFY'), (13, 'Tinchlik MFY'),
  -- Qo'shtepa tumani (14)
  (14, 'Bahor MFY'), (14, 'Do''stlik MFY'), (14, 'Markaziy MFY'), (14, 'Navro''z MFY'),
  -- So'x tumani (15)
  (15, 'Markaziy MFY'), (15, 'Oqsoy MFY'), (15, 'So''x MFY'), (15, 'Yangi hayot MFY'),
  -- Uchko'prik tumani (16)
  (16, 'Bog''ishamol MFY'), (16, 'Do''stlik MFY'), (16, 'Markaziy MFY'), (16, 'Navro''z MFY'),
  -- Yozyovon tumani (17)
  (17, 'Bahor MFY'), (17, 'G''alaba MFY'), (17, 'Markaziy MFY'), (17, 'Tinchlik MFY')
ON CONFLICT DO NOTHING;

-- Seed Data: Streets (Ko'chalar) - Har bir ko'cha o'z MFY iga bog'lanadi
INSERT INTO public.streets (neighborhood_id, name) VALUES
  -- Bag'ishamol MFY uchun (id=1, Farg'ona sh.)
  (1, 'Amir Temur ko''chasi'), (1, 'A. Navoiy ko''chasi'), (1, 'Asaka ko''chasi'), 
  -- Bahor MFY uchun (id=2)
  (2, 'Bahor ko''chasi'), (2, 'Bog''ishamol ko''chasi'), (2, 'Do''stlik ko''chasi'),
  -- Darvozaqo'rg'on MFY (id=3)
  (3, 'Fayz ko''chasi'), (3, 'G''alaba ko''chasi'), (3, 'Go''zal diyor ko''chasi'),
  -- Asaka MFY (Marg'ilon sh. id=27)
  (27, 'Guliston ko''chasi'), (27, 'Hamza ko''chasi'), (27, 'Istiqlol ko''chasi'),
  -- Ko'hna shahar MFY (id=11)
  (11, 'Ko''hna shahar ko''chasi'), (11, 'Markaziy ko''cha'), (11, 'Murabbiylar ko''chasi'),
  -- Boshqa MFY lar uchun
  (4, 'Mustaqillik ko''chasi'), (5, 'Navro''z ko''chasi'), (6, 'Navoiy ko''chasi'), 
  (7, 'Niyozbekhoja ko''chasi'), (8, 'Sarbon ko''chasi'), (9, 'Sulton Murodbek ko''chasi'), 
  (10, 'Tinchlik ko''chasi'), (11, 'Turkiston ko''chasi'), (12, 'Uychi ko''chasi'), 
  (13, 'Yangi hayot ko''chasi'), (14, 'Yangi ko''cha'), (15, 'Yashillik ko''chasi'), 
  (16, 'Yipak yo''li ko''chasi')
ON CONFLICT DO NOTHING;

-- ID hisoblagichlarini (Sequence) to'g'irlash (Qo'lda kiritilgan IDlar bilan konflikt bo'lmasligi uchun)
SELECT setval('districts_id_seq', (SELECT MAX(id) FROM districts));
SELECT setval('neighborhoods_id_seq', (SELECT MAX(id) FROM neighborhoods));
SELECT setval('streets_id_seq', (SELECT MAX(id) FROM streets));

-- 2. APP_USERS — Jadvallar
CREATE TABLE public.app_users (
  id               BIGSERIAL PRIMARY KEY,
  branch_id        BIGINT,
  district_id      BIGINT REFERENCES public.districts(id),
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
INSERT INTO public.app_users (first_name, last_name, username, password_hash, role, district_id)
VALUES
  ('Ali',    'Valiyev',   'surveyor1', '1234', 'SURVEYOR', 1),
  ('Bobur',  'Toshmatov', 'surveyor2', '1234', 'SURVEYOR', 2),
  ('Jasur',  'Rahimov',   'driver1',   '1234', 'DRIVER', 1),
  ('Dilnoza','Karimova',  'driver2',   '1234', 'DRIVER', 6),
  ('Usmoxan','Tadjibayev',  'superadmin',   '459775', 'ADMIN', 1)
ON CONFLICT (username) DO NOTHING;

-- 3. HOUSEHOLDS — Xonadonlar
CREATE TABLE public.households (
  id                    BIGSERIAL PRIMARY KEY,
  region_id             BIGINT NOT NULL DEFAULT 1,
  district_id           BIGINT REFERENCES public.districts(id),
  neighborhood_id       BIGINT REFERENCES public.neighborhoods(id),
  street_id             BIGINT REFERENCES public.streets(id),
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
  property_type         TEXT NOT NULL DEFAULT 'HOUSE' CHECK (property_type IN ('HOUSE', 'APARTMENT')),
  building_number       TEXT,
  floor                 INT,
  -- Eski text formatidagi ustunlar (migratsiya uchun yoki zaxira)
  tuman_name            TEXT,
  qfy_name              TEXT,
  mfy_name              TEXT,
  street_name           TEXT,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. RESIDENTS — Aholi
CREATE TABLE public.residents (
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
CREATE INDEX IF NOT EXISTS idx_neighborhood_dist   ON public.neighborhoods(district_id);

-- 5. RLS va POLICIES
ALTER TABLE public.districts     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.neighborhoods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.streets       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_users     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.households    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.residents     ENABLE ROW LEVEL SECURITY;

-- Politikalar
CREATE POLICY "allow_all_districts"     ON public.districts     FOR ALL    USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_neighborhoods" ON public.neighborhoods FOR ALL    USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_streets"       ON public.streets       FOR ALL    USING (true) WITH CHECK (true);
CREATE POLICY "allow_read_app_users"     ON public.app_users     FOR SELECT USING (true);
CREATE POLICY "allow_all_households"     ON public.households    FOR ALL    USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_residents"      ON public.residents     FOR ALL    USING (true) WITH CHECK (true);

