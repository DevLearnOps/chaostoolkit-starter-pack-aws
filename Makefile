.PHONY: clean format

clean:
	find . -type f -name 'chaostoolkit.log' -o -name 'journal.json' \
		| xargs rm -f
	find . -type d -name '__pycache__' -not -path '*/.venv/*' \
		| xargs rm -rf

format:
	find . -type f -name '*.py' -not -path '*/.venv/*' | xargs isort
	find . -type f -name '*.py' -not -path '*/.venv/*' | xargs black
	terraform -chdir=infrastructure/base/ fmt
	terraform -chdir=infrastructure/submodules/compute-environment/ fmt
	terraform -chdir=infrastructure/full/ fmt

submit-all:
	./push_to_ecr.sh
	find library -type f -name '*.conf' \
		| xargs python submit-job.py \
		--queue live-chaos-batch-job-queue \
		--job-definition live-chaos-batch-job-definition
