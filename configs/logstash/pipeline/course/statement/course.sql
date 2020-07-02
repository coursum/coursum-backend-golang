SELECT DISTINCT
  class_info.title,
  class_info.title_e,
  class_info.title_memo,
  class_info.title_memo_e,
  class_info.year,
  class_info.semester,
  class_info.class_day_code,
  class_info.class_type,
  class_info.class_room,
  class_info.reg_id,
  class_info.kamoku_sort,
  class_info.year_class_id
FROM
  class_info
WHERE
  class_info.year = 2019
  AND class_info.katei_code IN ('11')
  AND class_info.department IN ('23')
  AND class_info.cur IN ('2014')
LIMIT 1;
