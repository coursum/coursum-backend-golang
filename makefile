init:
	@make delete-course-index
	@make create-index-templates
	@make index-course-documents

delete-course-index:
	bash scripts/delete-course-index.sh

create-index-templates:
	bash scripts/create-index-templates.sh

index-course-documents:
	bash scripts/index-course-documents.sh

upload-all-ignored-files:
	bash scripts/upload-ignored-files.sh

upload-env:
	bash scripts/upload-ignored-files.sh --env

upload-database:
	bash scripts/upload-ignored-files.sh --database
