#!/bin/sh
echo "Executing container hogs: stress-ng ${HOG_CONFIG}"
SLEEP=${HOG_DELAY:-60}

# TODO: ability to randomly wait a certain amount of time before injecting the stressor
# this is useful to randomly render services unresponsive and check the load balancer 
# can detect and replace them.

eval "sleep ${SLEEP}"
exec $(eval "stress-ng ${HOG_CONFIG}")
