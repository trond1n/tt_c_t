CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  email varchar(320) NOT NULL UNIQUE,
  name varchar(100) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_users_updated_at ON users;
CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE OR REPLACE VIEW v_users AS
SELECT
  id,
  email,
  name,
  created_at,
  updated_at
FROM users;

CREATE OR REPLACE FUNCTION fn_create_user(p_email varchar, p_name varchar)
RETURNS TABLE (
  id uuid,
  email varchar,
  name varchar,
  created_at timestamptz,
  updated_at timestamptz
)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO users (email, name)
  VALUES (p_email, p_name);

  RETURN QUERY
  SELECT u.id, u.email, u.name, u.created_at, u.updated_at
  FROM v_users u
  WHERE u.email = p_email;
END;
$$;

CREATE OR REPLACE FUNCTION fn_update_user_name(p_user_id uuid, p_name varchar)
RETURNS TABLE (
  id uuid,
  email varchar,
  name varchar,
  created_at timestamptz,
  updated_at timestamptz
)
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE users
  SET name = p_name
  WHERE users.id = p_user_id;

  RETURN QUERY
  SELECT u.id, u.email, u.name, u.created_at, u.updated_at
  FROM v_users u
  WHERE u.id = p_user_id;
END;
$$;
