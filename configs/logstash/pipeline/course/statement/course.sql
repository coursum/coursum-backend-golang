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
   GROUP BY auth_faculty.projectid), --
class_master AS /* Filter class_master by guide_u (remove old category data)*/
  (SELECT *
   FROM class_master /* TODO: find another way to maintain the list */
   WHERE class_master.guide_u IN (' 1.研究プロジェクト科目',
                                  ' 2.基盤科目-総合講座科目',
                                  ' 3.基盤科目-言語コミュニケーション科目',
                                  ' 4.基盤科目-データサイエンス科目-データサイエンス１',
                                  ' 5.基盤科目-データサイエンス科目-データサイエンス２',
                                  ' 6.基盤科目-情報技術基礎科目',
                                  ' 7.基盤科目-ウェルネス科目',
                                  ' 8.基盤科目-共通科目',
                                  ' 9.先端科目-総合政策系',
                                  '10.先端科目-環境情報系',
                                  '11.特設科目',
                                  '12.教職課程教科に関する科目',
                                  '13.自由科目',
                                  '14.SFC設置の諸研究所科目') )
SELECT DISTINCT class_info.title,
                class_info.title_e,
                class_info.title_memo,
                class_info.title_memo_e,
                class_lecturers.lecturer_ids,
                class_lecturers.lecturer_types,
                class_lecturers.lecturer_names_ja,
                class_lecturers.lecturer_names_kana,
                class_lecturers.lecturer_names_en,
                class_lecturers.lecturer_imgs,
                class_lecturers.lecturer_emails,
                class_info.year,
                class_info.semester,
                class_info.class_day_code,
                class_info.class_type,
                class_info.class_room,
                class_master.credit,
                summary_info.language,
                class_master.guide_u,
                class_master.guide_u_e,
                summary_info.summary,
                summary_info.summary_e,
                summary_info.a_class_type,
                class_info.reg_id,
                summary_info.g0,
                summary_info.g1,
                summary_info.condition,
                summary_info.condition_e,
                summary_info.pre_req,
                summary_info.pre_req_e,
                summary_info.g2,
                class_info.kamoku_sort,
                class_info.year_class_id,
                summary_info.giga_class
FROM class_info
LEFT JOIN class_lecturers ON class_info.year_class_id = class_lecturers.year_class_id
LEFT JOIN class_master ON class_info.kamoku_sort = class_master.kamoku_sort
LEFT JOIN summary_info ON class_info.year_class_id = summary_info.year_class_id
LIMIT 1;
