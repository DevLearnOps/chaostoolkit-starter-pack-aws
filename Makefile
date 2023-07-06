.PHONY: clean format

clean:
	find . -name 'chaostoolkit.log' -o -name 'journal.json' \
		| xargs rm -f

format:
	find . -type f -name '*.py' | xargs isort
	find . -type f -name '*.py' | xargs black
