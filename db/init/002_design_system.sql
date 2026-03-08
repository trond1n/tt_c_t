CREATE TABLE IF NOT EXISTS ui_component_categories (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  slug text NOT NULL UNIQUE,
  name text NOT NULL,
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS ui_components (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_id uuid NOT NULL REFERENCES ui_component_categories(id),
  slug text NOT NULL UNIQUE,
  name text NOT NULL,
  description text NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'archived')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS ui_component_versions (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  component_id uuid NOT NULL REFERENCES ui_components(id),
  version_no int NOT NULL,
  is_published boolean NOT NULL DEFAULT false,
  props_schema jsonb NOT NULL DEFAULT '{}'::jsonb,
  figma_node_id text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (component_id, version_no)
);

CREATE TABLE IF NOT EXISTS layout_pages (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  slug text NOT NULL UNIQUE,
  name text NOT NULL,
  layout_type text NOT NULL DEFAULT 'desktop' CHECK (layout_type IN ('desktop')),
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'archived')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS layout_page_versions (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  page_id uuid NOT NULL REFERENCES layout_pages(id),
  version_no int NOT NULL,
  is_published boolean NOT NULL DEFAULT false,
  figma_node_id text,
  canvas_width int NOT NULL DEFAULT 1440,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (page_id, version_no)
);

CREATE TABLE IF NOT EXISTS layout_sections (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  page_version_id uuid NOT NULL REFERENCES layout_page_versions(id),
  name text NOT NULL,
  section_order int NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (page_version_id, section_order)
);

CREATE TABLE IF NOT EXISTS layout_nodes (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  section_id uuid NOT NULL REFERENCES layout_sections(id),
  node_type text NOT NULL CHECK (node_type IN ('component', 'container', 'text', 'image')),
  node_order int NOT NULL,
  x int NOT NULL,
  y int NOT NULL,
  w int NOT NULL,
  h int NOT NULL,
  props jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE VIEW v_ui_components_catalog AS
SELECT
  c.id AS component_id,
  c.slug AS component_slug,
  c.name AS component_name,
  c.status AS component_status,
  cat.slug AS category_slug,
  cat.name AS category_name,
  v.version_no AS published_version_no,
  v.props_schema AS published_props_schema
FROM ui_components c
JOIN ui_component_categories cat ON cat.id = c.category_id
LEFT JOIN ui_component_versions v ON v.component_id = c.id AND v.is_published = true;

CREATE OR REPLACE VIEW v_layout_desktop_pages AS
SELECT
  p.id AS page_id,
  p.slug AS page_slug,
  p.name AS page_name,
  p.status AS page_status,
  pv.version_no AS published_version_no,
  pv.figma_node_id,
  pv.canvas_width
FROM layout_pages p
LEFT JOIN layout_page_versions pv ON pv.page_id = p.id AND pv.is_published = true
WHERE p.layout_type = 'desktop';

CREATE OR REPLACE FUNCTION fn_create_component(
  p_category_slug text,
  p_component_slug text,
  p_component_name text,
  p_description text
)
RETURNS TABLE (
  component_id uuid,
  component_slug text,
  component_name text,
  category_slug text
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_category_id uuid;
BEGIN
  SELECT id INTO v_category_id
  FROM ui_component_categories
  WHERE slug = p_category_slug;

  IF v_category_id IS NULL THEN
    INSERT INTO ui_component_categories (slug, name)
    VALUES (p_category_slug, initcap(replace(p_category_slug, '-', ' ')))
    RETURNING id INTO v_category_id;
  END IF;

  INSERT INTO ui_components (category_id, slug, name, description, status)
  VALUES (v_category_id, p_component_slug, p_component_name, coalesce(p_description, ''), 'draft');

  RETURN QUERY
  SELECT c.id, c.slug, c.name, cat.slug
  FROM ui_components c
  JOIN ui_component_categories cat ON cat.id = c.category_id
  WHERE c.slug = p_component_slug;
END;
$$;

CREATE OR REPLACE FUNCTION fn_create_layout_page(
  p_page_slug text,
  p_page_name text
)
RETURNS TABLE (
  page_id uuid,
  page_slug text,
  page_name text,
  layout_type text
)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO layout_pages (slug, name, layout_type, status)
  VALUES (p_page_slug, p_page_name, 'desktop', 'draft');

  RETURN QUERY
  SELECT id, slug, name, layout_type
  FROM layout_pages
  WHERE slug = p_page_slug;
END;
$$;
