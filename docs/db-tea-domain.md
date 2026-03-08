# Tea domain DB design (left menu + brewing recommendations)

Этот документ закрывает ваш сценарий:
- в левом меню отображается база чаёв;
- у чая хранится сорт (тип);
- у чая хранится профиль заваривания;
- план проливов можно получать функцией как массив шагов.

## 1) Сущности

- `tea_types` — база сортов (зеленый, улун, шен пуэр и т.д.)
- `teas` — база чаёв (Лун Цзин, Да Хун Пао и т.д.)
- `tea_brewing_profiles` — параметры заваривания для каждого чая:
  - `water_temp_c`
  - `optimal_infusions`
  - `base_time_sec`
  - `step_time_sec`
  - `calculation_mode` (`linear` / `custom`)
- `tea_brewing_custom_steps` — кастомные времена проливов (если линейной формулы недостаточно)

## 2) Чтение через VIEW

- `v_tea_menu_items` — данные для левого меню (чай + сорт + профиль)
- `v_tea_brewing_profiles` — профиль заваривания по чаю

## 3) Запись и вычисление через FUNCTION

- `fn_upsert_tea_type` — создать/обновить сорт
- `fn_create_tea` — создать чай с привязкой к сорту
- `fn_upsert_tea_brewing_profile` — создать/обновить профиль заваривания
- `fn_set_tea_custom_step` — задать кастомный шаг пролива
- `fn_get_tea_brew_plan(tea_id)` — получить итоговый план проливов

## 4) Логика расчета плана проливов

### Вариант A: `linear`

Функция `fn_get_tea_brew_plan` строит шаги по формуле:

`time_sec = base_time_sec + (infusion_no - 1) * step_time_sec`

Пример:
- `optimal_infusions = 5`
- `base_time_sec = 10`
- `step_time_sec = 10`

Результат:

```json
[
  { "infusion_no": 1, "time_sec": 10 },
  { "infusion_no": 2, "time_sec": 20 },
  { "infusion_no": 3, "time_sec": 30 },
  { "infusion_no": 4, "time_sec": 40 },
  { "infusion_no": 5, "time_sec": 50 }
]
```

### Вариант B: `custom`

Если для чая нужна индивидуальная кривая, задаются шаги в `tea_brewing_custom_steps`.
Тогда `fn_get_tea_brew_plan` возвращает именно их.

## 5) Почему это оптимально

- Просто для типовых чаёв (`linear`)
- Гибко для сложных чаёв (`custom`)
- Полностью соответствует вашему правилу:
  - данные в таблицах
  - SELECT через view
  - изменения/бизнес-логика через функции
