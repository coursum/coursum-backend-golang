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

# strip that support removing full-width space
def strip_space(str)
  (str || '').gsub(/^[[:space:]]*|[[:space:]]*$/, '')
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

# " 1.abc - def - ghi" => ["abc", "def", "ghi"]
def parse_category(category)
  category.gsub(/[[:space:]]*\d+\./, '')
          .split(/[[:space:]]*-[[:space:]]*/)
end

def translate_language(language_code, locale)
  translate(locale) do |target|
    target['language'][language_code] || target['language']['fallback']
  end
end

def translate_category_from_en_to_ja(category)
  translate('ja', 'en') do |target, source|
    key = source['category'].key(category)

    target['category'][key]
  end
end

def translate_types_from_ja_to_en(types)
  types.map do |type|
    translate('en', 'ja') do |target, source|
      key = source['class_type'].key(type)

      target['class_type'][key]
    end
  end
end

def filter(event)
  title_name_ja = event.get('title')
  title_name_en = event.get('title_e')
  title_postscript_ja = event.get('title_memo') || ''
  title_postscript_en = event.get('title_memo_e') || ''

  lecturer_ids = event.get('lecturer_ids') || []
  lecturer_types = event.get('lecturer_types') || []
  lecturer_names_ja = event.get('lecturer_names_ja') || []
  lecturer_names_kana = event.get('lecturer_names_kana') || []
  lecturer_names_en = event.get('lecturer_names_en') || []
  lecturer_imgs = event.get('lecturer_imgs') || []
  lecturer_emails = event.get('lecturer_emails') || []

  lecturers = lecturer_ids.map.with_index do |_, index|
    lecturer_id = lecturer_ids[index]
    # TODO: process the value in SQL
    lecturer_is_in_charge = lecturer_types[index] == 10
    lecturer_name_ja = strip_space(lecturer_names_ja[index])
    lecturer_name_kana = strip_space(lecturer_names_kana[index])
    lecturer_name_en = strip_space(lecturer_names_en[index])
    lecturer_img_url = lecturer_imgs[index] || ''
    lecturer_email = lecturer_emails[index] || ''

    {
      id: lecturer_id,
      isInCharge: lecturer_is_in_charge,
      name: {
        ja: lecturer_name_ja,
        kana: lecturer_name_kana,
        en: lecturer_name_en
      },
      imgUrl: lecturer_img_url,
      email: lecturer_email
    }
  end

  schedule_year = event.get('year').to_i
  schedule_semester_ja = event.get('semester')
  schedule_semester_en = translate_semester_from_ja_to_en(event.get('semester'))
  class_day_codes = split_sort(event.get('class_day_code'), ',')
  schedule_times_ja = parse_class_day_codes(class_day_codes, 'ja')
  schedule_times_en = parse_class_day_codes(class_day_codes, 'en')
  # TODO: Investigate class_info column and translate to English
  schedule_span_ja = event.get('class_type')

  # TODO: Investigate and process class_room column
  # maybe by split_sort(event.get('class_room'), ',')
  classroom = event.get('class_room') || ''

  # TODO: Finding a proper fallback value for credit.
  # For courses like PE, there is no credit.
  credit = event.get('credit') || 0

  language = event.get('language')
  language_ja = translate_language(language, 'ja')
  language_en = translate_language(language, 'en')

  category_en = parse_category(event.get('guide_u_e'))
  category_ja = parse_category(translate_category_from_en_to_ja(event.get('guide_u_e')))

  summary_ja = strip_space(event.get('summary'))
  summary_en = strip_space(event.get('summary_e'))

  types_ja = split_sort(event.get('a_class_type'), '、')
  types_en = translate_types_from_ja_to_en(types_ja)

  registration_number = event.get('reg_id')
  registration_prerequisite_mandatory = split_sort(event.get('g0'), ',')
  registration_prerequisite_recommended = split_sort(event.get('g1'), ',').reject do |str|
    registration_prerequisite_mandatory.include?(str)
  end
  registration_requirement_ja = strip_space(event.get('condition'))
  registration_requirement_en = strip_space(event.get('condition_e'))
  registration_suggestion_ja = strip_space(event.get('pre_req'))
  registration_suggestion_en = strip_space(event.get('pre_req_e'))

  related = split_sort(event.get('g2'), ',')

  curriculum_code = event.get('kamoku_sort')
  year_class_id = event.get('year_class_id')

  tag_is_giga = event.get('giga_class') || false

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
    classroom: classroom,
    credit: credit,
    language: {
      ja: language_ja,
      en: language_en
    },
    category: {
      ja: category_ja,
      en: category_en
    },
    summary: {
      ja: summary_ja,
      en: summary_en
    },
    types: {
      ja: types_ja,
      en: types_en
    },
    registration: {
      number: registration_number,
      prerequisite: {
        mandatory: registration_prerequisite_mandatory,
        recommended: registration_prerequisite_recommended
      },
      requirement: {
        ja: registration_requirement_ja,
        en: registration_requirement_en
      },
      suggestion: {
        ja: registration_suggestion_ja,
        en: registration_suggestion_en
      }
    },
    related: related,
    curriculumCode: curriculum_code,
    yearClassId: year_class_id,
    tag: {
      isGIGA: tag_is_giga
    }
  }

  event.initialize(course)

  [event]
end
