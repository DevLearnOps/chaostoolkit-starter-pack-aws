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
