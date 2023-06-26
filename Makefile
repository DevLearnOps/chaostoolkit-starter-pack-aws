.PHONY: clean

clean:
	find . -name 'chaostoolkit.log' -o -name 'journal.json' \
		| xargs rm -f
