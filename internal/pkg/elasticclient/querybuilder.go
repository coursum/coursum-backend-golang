package elasticclient

import "github.com/olivere/elastic/v7"

func BuildQuery(options SearchOptions) *elastic.BoolQuery {
	fields := []string{
		"title*",
		"summary*",
		"curriculumCode",
	}

	var conditions []elastic.Query

	if options.Giga {
		conditions = append(conditions, elastic.NewTermQuery("tag.giga", true))
	}

	if options.Language != "" {
		conditions = append(conditions, elastic.NewTermQuery("language.en.keyword", options.Language))
	} else {
		fields = append(fields, "language*")
	}

	if options.Classroom != "" {
		conditions = append(conditions, elastic.NewTermQuery("classroom.keyword", options.Classroom))
	}

	if options.Category != "" {
		conditions = append(conditions, elastic.NewMultiMatchQuery(options.Category, "category*"))
	} else {
		fields = append(fields, "category*")
	}

	if options.Semester != "" {
		conditions = append(conditions, elastic.NewMultiMatchQuery(options.Semester, "schedule.semester*"))
	} else {
		fields = append(fields, "schedule.semester*")
	}

	if options.Teacher != "" {
		conditions = append(conditions, elastic.NewMultiMatchQuery(options.Teacher, "lecturers.name*"))
	} else {
		fields = append(fields, "lecturers.name*")
	}

	if options.Times != "" {
		conditions = append(conditions, elastic.NewMultiMatchQuery(options.Times, "schedule.times*"))
	} else {
		fields = append(fields, "schedule.times*")
	}

	if options.Query != "" {
		conditions = append(conditions,
			elastic.NewMultiMatchQuery(
				options.Query,
				fields...).
				Type("cross_fields").
				Operator("And"))
	}

	return elastic.NewBoolQuery().Must(conditions...)
}
