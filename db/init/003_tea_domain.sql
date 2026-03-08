-- Tea domain for left menu and brewing recommendations
-- Pattern: tables store data, reads from views, writes/calculation via functions.

CREATE TABLE IF NOT EXISTS tea_types (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  slug text NOT NULL UNIQUE,
  name text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS teas (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  slug text NOT NULL UNIQUE,
  name text NOT NULL,
  tea_type_id uuid NOT NULL REFERENCES tea_types(id),
  description text NOT NULL DEFAULT '',
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS tea_brewing_profiles (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  tea_id uuid NOT NULL UNIQUE REFERENCES teas(id),
  water_temp_c int NOT NULL CHECK (water_temp_c BETWEEN 50 AND 100),
  optimal_infusions int NOT NULL CHECK (optimal_infusions BETWEEN 1 AND 20),
  base_time_sec int NOT NULL CHECK (base_time_sec BETWEEN 1 AND 600),
  step_time_sec int NOT NULL DEFAULT 10 CHECK (step_time_sec BETWEEN 0 AND 120),
  calculation_mode text NOT NULL DEFAULT 'linear' CHECK (calculation_mode IN ('linear', 'custom')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS tea_brewing_custom_steps (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  brewing_profile_id uuid NOT NULL REFERENCES tea_brewing_profiles(id) ON DELETE CASCADE,
  infusion_no int NOT NULL CHECK (infusion_no >= 1),
  time_sec int NOT NULL CHECK (time_sec BETWEEN 1 AND 1200),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (brewing_profile_id, infusion_no)
);

CREATE OR REPLACE VIEW v_tea_menu_items AS
SELECT
  t.id AS tea_id,
  t.slug AS tea_slug,
  t.name AS tea_name,
  tt.id AS tea_type_id,
  tt.slug AS tea_type_slug,
  tt.name AS tea_type_name,
  p.water_temp_c,
  p.optimal_infusions,
  p.base_time_sec,
  p.step_time_sec,
  p.calculation_mode
FROM teas t
JOIN tea_types tt ON tt.id = t.tea_type_id
LEFT JOIN tea_brewing_profiles p ON p.tea_id = t.id
WHERE t.is_active = true;

CREATE OR REPLACE VIEW v_tea_brewing_profiles AS
SELECT
  p.id AS profile_id,
  t.id AS tea_id,
  t.slug AS tea_slug,
  t.name AS tea_name,
  p.water_temp_c,
  p.optimal_infusions,
  p.base_time_sec,
  p.step_time_sec,
  p.calculation_mode
FROM tea_brewing_profiles p
JOIN teas t ON t.id = p.tea_id;

CREATE OR REPLACE FUNCTION fn_upsert_tea_type(
  p_slug text,
  p_name text
)
RETURNS TABLE (
  tea_type_id uuid,
  slug text,
  name text
)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO tea_types (slug, name)
  VALUES (p_slug, p_name)
  ON CONFLICT (slug)
  DO UPDATE SET
    name = EXCLUDED.name,
    updated_at = now();

  RETURN QUERY
  SELECT id, tea_types.slug, tea_types.name
  FROM tea_types
  WHERE tea_types.slug = p_slug;
END;
$$;

CREATE OR REPLACE FUNCTION fn_create_tea(
  p_slug text,
  p_name text,
  p_tea_type_slug text,
  p_description text
)
RETURNS TABLE (
  tea_id uuid,
  tea_slug text,
  tea_name text,
  tea_type_slug text
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_tea_type_id uuid;
BEGIN
  SELECT id INTO v_tea_type_id
  FROM tea_types
  WHERE slug = p_tea_type_slug;

  IF v_tea_type_id IS NULL THEN
    RAISE EXCEPTION 'tea type with slug % was not found', p_tea_type_slug;
  END IF;

  INSERT INTO teas (slug, name, tea_type_id, description)
  VALUES (p_slug, p_name, v_tea_type_id, COALESCE(p_description, ''));

  RETURN QUERY
  SELECT t.id, t.slug, t.name, tt.slug
  FROM teas t
  JOIN tea_types tt ON tt.id = t.tea_type_id
  WHERE t.slug = p_slug;
END;
$$;

CREATE OR REPLACE FUNCTION fn_upsert_tea_brewing_profile(
  p_tea_id uuid,
  p_water_temp_c int,
  p_optimal_infusions int,
  p_base_time_sec int,
  p_step_time_sec int,
  p_calculation_mode text
)
RETURNS TABLE (
  profile_id uuid,
  tea_id uuid,
  water_temp_c int,
  optimal_infusions int,
  base_time_sec int,
  step_time_sec int,
  calculation_mode text
)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO tea_brewing_profiles (
    tea_id,
    water_temp_c,
    optimal_infusions,
    base_time_sec,
    step_time_sec,
    calculation_mode
  )
  VALUES (
    p_tea_id,
    p_water_temp_c,
    p_optimal_infusions,
    p_base_time_sec,
    p_step_time_sec,
    p_calculation_mode
  )
  ON CONFLICT (tea_id)
  DO UPDATE SET
    water_temp_c = EXCLUDED.water_temp_c,
    optimal_infusions = EXCLUDED.optimal_infusions,
    base_time_sec = EXCLUDED.base_time_sec,
    step_time_sec = EXCLUDED.step_time_sec,
    calculation_mode = EXCLUDED.calculation_mode,
    updated_at = now();

  RETURN QUERY
  SELECT p.id, p.tea_id, p.water_temp_c, p.optimal_infusions, p.base_time_sec, p.step_time_sec, p.calculation_mode
  FROM tea_brewing_profiles p
  WHERE p.tea_id = p_tea_id;
END;
$$;

CREATE OR REPLACE FUNCTION fn_set_tea_custom_step(
  p_tea_id uuid,
  p_infusion_no int,
  p_time_sec int
)
RETURNS TABLE (
  profile_id uuid,
  infusion_no int,
  time_sec int
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_profile_id uuid;
BEGIN
  SELECT id INTO v_profile_id
  FROM tea_brewing_profiles
  WHERE tea_id = p_tea_id;

  IF v_profile_id IS NULL THEN
    RAISE EXCEPTION 'brewing profile for tea % was not found', p_tea_id;
  END IF;

  UPDATE tea_brewing_profiles
  SET calculation_mode = 'custom', updated_at = now()
  WHERE id = v_profile_id;

  INSERT INTO tea_brewing_custom_steps (brewing_profile_id, infusion_no, time_sec)
  VALUES (v_profile_id, p_infusion_no, p_time_sec)
  ON CONFLICT (brewing_profile_id, infusion_no)
  DO UPDATE SET time_sec = EXCLUDED.time_sec;

  RETURN QUERY
  SELECT v_profile_id, p_infusion_no, p_time_sec;
END;
$$;

CREATE OR REPLACE FUNCTION fn_get_tea_brew_plan(
  p_tea_id uuid
)
RETURNS TABLE (
  infusion_no int,
  time_sec int
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_profile tea_brewing_profiles%ROWTYPE;
BEGIN
  SELECT * INTO v_profile
  FROM tea_brewing_profiles
  WHERE tea_id = p_tea_id;

  IF v_profile.id IS NULL THEN
    RAISE EXCEPTION 'brewing profile for tea % was not found', p_tea_id;
  END IF;

  IF v_profile.calculation_mode = 'custom' THEN
    RETURN QUERY
    SELECT s.infusion_no, s.time_sec
    FROM tea_brewing_custom_steps s
    WHERE s.brewing_profile_id = v_profile.id
    ORDER BY s.infusion_no;

    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    gs AS infusion_no,
    v_profile.base_time_sec + ((gs - 1) * v_profile.step_time_sec) AS time_sec
  FROM generate_series(1, v_profile.optimal_infusions) gs;
END;
$$;
