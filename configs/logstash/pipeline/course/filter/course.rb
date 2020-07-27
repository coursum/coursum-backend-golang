# frozen_string_literal: true

require 'json'

def load_locale_message(locale)
  locale_path = '/usr/share/logstash/pipeline/course/locales/%s.json'
  JSON.parse(File.read(locale_path % locale))
end

def translate(target_locale, source_locale = nil, &block)
  target_messages = load_locale_message(target_locale)
  source_messages = load_locale_message(source_locale) unless source_locale.nil?

  block.call(target_messages, source_messages)
end

def split_sort(str, pattern)
  (str || '').split(pattern).reject(&:empty?).sort
end

def translate_semester_from_ja_to_en(semester)
  translate('en', 'ja') do |target, source|
    key = source['semester'].key(semester)

    target['semester'][key]
  end
end

def parse_class_day_codes(class_day_codes, locale)
  message = load_locale_message(locale)
  day_of_week_list = message['dayOfWeekList']
  period_list = message['periodList']
  separator = message['classTimeCodeSeparator']

  class_day_codes.map do |class_day_code|
    day_of_week_code, period_code = class_day_code.split('').map { |code| code.to_i - 1 }
    day_of_week = day_of_week_list[day_of_week_code]
    period = period_list[period_code]

    "#{day_of_week}#{separator}#{period}"
  end
end

def filter(event)
  title_name_ja = event.get('title')
  title_name_en = event.get('title_e')
  title_postscript_ja = event.get('title_memo') || ''
  title_postscript_en = event.get('title_memo_e') || ''

  schedule_year = event.get('year').to_i
  schedule_semester_ja = event.get('semester')
  schedule_semester_en = translate_semester_from_ja_to_en(event.get('semester'))
  class_day_codes = split_sort(event.get('class_day_code'), ',')
  schedule_times_ja = parse_class_day_codes(class_day_codes, 'ja')
  schedule_times_en = parse_class_day_codes(class_day_codes, 'en')
  # TODO: Investigate class_info column and translate to English
  schedule_span_ja = event.get('class_type')

  classroom = event.get('class_room')

  registration_number = event.get('reg_id')

  curriculum_code = event.get('kamoku_sort')
  year_class_id = event.get('year_class_id')

  lecturer_ids = event.get('lecturer_ids')
  lecturer_types = event.get('lecturer_types')
  lecturer_names_ja = event.get('lecturer_names_ja')
  lecturer_names_kana = event.get('lecturer_names_kana')
  lecturer_names_en = event.get('lecturer_names_en')
  lecturer_emails = event.get('lecturer_emails')

  lecturers = lecturer_ids.map.with_index do |_, index|
    lecturer_id = lecturer_ids[index]
    # TODO: process the value in SQL
    lecturer_is_in_charge = lecturer_types[index] == 10
    lecturer_name_ja = lecturer_names_ja[index]
    lecturer_name_kana = lecturer_names_kana[index]
    lecturer_name_en = lecturer_names_en[index]
    lecturer_email = lecturer_emails[index]

    {
      id: lecturer_id,
      isInCharge: lecturer_is_in_charge,
      name: {
        ja: lecturer_name_ja,
        kana: lecturer_name_kana,
        en: lecturer_name_en
      },
      email: lecturer_email
    }
  end

  course = {
    title: {
      name: {
        ja: title_name_ja,
        en: title_name_en
      },
      postscript: {
        ja: title_postscript_ja,
        en: title_postscript_en
      }
    },
    lecturers: lecturers,
    schedule: {
      year: schedule_year,
      semester: {
        ja: schedule_semester_ja,
        en: schedule_semester_en
      },
      times: {
        ja: schedule_times_ja,
        en: schedule_times_en
      },
      span: {
        ja: schedule_span_ja
      }
    },
    registration: {
      number: registration_number
    },
    classroom: classroom,
    curriculumCode: curriculum_code,
    yearClassId: year_class_id
  }

  event.initialize(course)

  [event]
end
