# DB design proposal: Figma pages "Компоненты" + "Макеты десктоп"

> Цель: подготовить основу БД до реализации backend/frontend.
> Подход: **table -> view -> function**.

## 1. Domain blocks

- UI catalog (компоненты дизайн-системы)
- Desktop layouts (страницы/макеты)
- Token system (цвета, отступы, типографика и т.п.)
- Asset storage (иконки, изображения)
- Audit trail

## 2. Tables (write model)

### 2.1 UI components

- `ui_component_categories`
  - `id uuid pk`
  - `slug text unique`
  - `name text`
  - `sort_order int`
  - `created_at`, `updated_at`

- `ui_components`
  - `id uuid pk`
  - `category_id uuid fk -> ui_component_categories.id`
  - `slug text unique`
  - `name text`
  - `description text`
  - `status text check (status in ('draft','active','archived'))`
  - `created_at`, `updated_at`

- `ui_component_versions`
  - `id uuid pk`
  - `component_id uuid fk -> ui_components.id`
  - `version_no int`
  - `is_published boolean`
  - `props_schema jsonb`
  - `figma_node_id text`
  - `created_at`, `updated_at`
  - unique `(component_id, version_no)`

- `ui_component_variants`
  - `id uuid pk`
  - `version_id uuid fk -> ui_component_versions.id`
  - `variant_key text` (например `size=lg;theme=dark;state=hover`)
  - `preview_asset_id uuid fk -> assets.id`
  - `props_override jsonb`
  - `created_at`, `updated_at`
  - unique `(version_id, variant_key)`

### 2.2 Desktop layouts

- `layout_pages`
  - `id uuid pk`
  - `slug text unique`
  - `name text`
  - `layout_type text check (layout_type in ('desktop'))`
  - `status text check (status in ('draft','active','archived'))`
  - `created_at`, `updated_at`

- `layout_page_versions`
  - `id uuid pk`
  - `page_id uuid fk -> layout_pages.id`
  - `version_no int`
  - `is_published boolean`
  - `figma_node_id text`
  - `canvas_width int`
  - `created_at`, `updated_at`
  - unique `(page_id, version_no)`

- `layout_sections`
  - `id uuid pk`
  - `page_version_id uuid fk -> layout_page_versions.id`
  - `name text`
  - `section_order int`
  - `created_at`, `updated_at`
  - unique `(page_version_id, section_order)`

- `layout_nodes`
  - `id uuid pk`
  - `section_id uuid fk -> layout_sections.id`
  - `node_type text check (node_type in ('component','container','text','image'))`
  - `node_order int`
  - `x int`, `y int`, `w int`, `h int`
  - `props jsonb`
  - `created_at`, `updated_at`

- `layout_node_component_bindings`
  - `id uuid pk`
  - `layout_node_id uuid unique fk -> layout_nodes.id`
  - `component_version_id uuid fk -> ui_component_versions.id`
  - `component_variant_id uuid null fk -> ui_component_variants.id`
  - `created_at`, `updated_at`

### 2.3 Tokens and assets

- `design_tokens`
  - `id uuid pk`
  - `token_type text check (token_type in ('color','spacing','radius','typography','shadow'))`
  - `token_name text unique`
  - `token_value jsonb`
  - `created_at`, `updated_at`

- `component_token_links`
  - `id uuid pk`
  - `component_version_id uuid fk -> ui_component_versions.id`
  - `token_id uuid fk -> design_tokens.id`
  - `usage_hint text`
  - unique `(component_version_id, token_id, usage_hint)`

- `assets`
  - `id uuid pk`
  - `asset_type text check (asset_type in ('image','icon','svg','font'))`
  - `storage_key text unique`
  - `mime_type text`
  - `meta jsonb`
  - `created_at`, `updated_at`

### 2.4 Audit

- `audit_log`
  - `id uuid pk`
  - `actor_id text`
  - `action text`
  - `entity_type text`
  - `entity_id uuid`
  - `payload jsonb`
  - `created_at`

## 3. Views (read model)

- `v_ui_components_catalog`
  - для страницы “Компоненты” (список карточек + категория + опубликованная версия)

- `v_ui_component_variants`
  - для детального просмотра вариантов

- `v_layout_desktop_pages`
  - список desktop-макетов

- `v_layout_desktop_page_full`
  - денормализованный graph: page_version -> sections -> nodes -> bound components/variants

- `v_design_tokens`
  - read model для токенов

## 4. Functions (write API)

- UI:
  - `fn_create_component(category_slug, component_slug, component_name, description)`
  - `fn_create_component_version(component_slug, version_no, props_schema, figma_node_id)`
  - `fn_publish_component_version(component_slug, version_no)`
  - `fn_upsert_component_variant(component_slug, version_no, variant_key, props_override, preview_asset_key)`

- Layout:
  - `fn_create_layout_page(page_slug, page_name)`
  - `fn_create_layout_page_version(page_slug, version_no, figma_node_id, canvas_width)`
  - `fn_add_layout_section(page_slug, version_no, section_name, section_order)`
  - `fn_add_layout_node(page_slug, version_no, section_order, node_type, node_order, x, y, w, h, props)`
  - `fn_bind_component_to_layout_node(layout_node_id, component_slug, version_no, variant_key)`
  - `fn_publish_layout_page_version(page_slug, version_no)`

- Tokens/assets:
  - `fn_upsert_design_token(token_type, token_name, token_value)`
  - `fn_attach_token_to_component(component_slug, version_no, token_name, usage_hint)`
  - `fn_create_asset(asset_type, storage_key, mime_type, meta)`

Все операции INSERT/UPDATE/DELETE происходят только внутри `fn_*`.

## 5. API modules for backend (next step)

- `components` module
  - read: `v_ui_components_catalog`, `v_ui_component_variants`
  - write: `fn_create_component*`, `fn_publish_component_version`, `fn_upsert_component_variant`

- `layouts` module
  - read: `v_layout_desktop_pages`, `v_layout_desktop_page_full`
  - write: `fn_create_layout_*`, `fn_add_layout_*`, `fn_bind_component_to_layout_node`, `fn_publish_layout_page_version`

- `tokens` module
  - read: `v_design_tokens`
  - write: `fn_upsert_design_token`, `fn_attach_token_to_component`

