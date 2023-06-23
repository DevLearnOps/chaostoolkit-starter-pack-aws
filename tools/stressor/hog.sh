#!/bin/sh
echo "Executing container hogs: stress-ng ${HOG_CONFIG}"
SLEEP=${HOG_DELAY:-60}

eval "sleep ${SLEEP}"
exec $(eval "stress-ng ${HOG_CONFIG}")
