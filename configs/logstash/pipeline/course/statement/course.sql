WITH class_info AS /* Filter class_info by criteria */
  (SELECT *
   FROM class_info
   WHERE class_info.year = 2019
     AND class_info.katei_code IN ('11')
     AND class_info.department IN ('23')
     AND class_info.cur IN ('2014') ), --
auth AS /* Filter auth by class_info */
  (SELECT DISTINCT auth.*
   FROM auth
   INNER JOIN class_info ON auth.projectid = class_info.year_class_id), --
auth_faculty AS /* JOIN filterd auth with faculty */
  (SELECT *
   FROM auth
   LEFT JOIN faculty ON auth.userid = faculty.id
   ORDER BY auth.projectid ASC, array_position(ARRAY[10, 1]::numeric[], auth.faculty_type) ASC, auth.userid ASC), --
class_lecturers AS /* Aggregate columns by auth.projectid */
  (SELECT DISTINCT auth_faculty.projectid AS year_class_id,
                   array_agg(auth_faculty.userid) AS lecturer_ids,
                   array_agg(auth_faculty.faculty_type) AS lecturer_types,
                   array_agg(auth_faculty.name) AS lecturer_names_ja,
                   array_agg(auth_faculty.name_kana) AS lecturer_names_kana,
                   array_agg(auth_faculty.name_english) AS lecturer_names_en,
                   array_agg(auth_faculty.img) AS lecturer_imgs,
                   array_agg(auth_faculty.email) AS lecturer_emails
   FROM auth_faculty
   GROUP BY auth_faculty.projectid)
SELECT DISTINCT class_info.title,
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
                class_info.year_class_id,
                class_lecturers.lecturer_ids,
                class_lecturers.lecturer_types,
                class_lecturers.lecturer_names_ja,
                class_lecturers.lecturer_names_kana,
                class_lecturers.lecturer_names_en,
                class_lecturers.lecturer_imgs,
                class_lecturers.lecturer_emails
FROM class_info
LEFT JOIN class_lecturers ON class_info.year_class_id = class_lecturers.year_class_id
LIMIT 1;
