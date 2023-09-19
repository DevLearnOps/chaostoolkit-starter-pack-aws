# Tasks Failure

This experiment simulates the failure of half of the tasks. This can help determine if your infrastructure is able to recover in a timely manner.

## Business Value

Although AWS ECS already provides automation to automatically recover from tasks failure, we have the responsibility to verify that service healthchecks and load balancing algorithms are configured correctly to efficiently identify and restart failing containers.

## System Requirements

**Python Packages**

* chaostoolkit-aws

## Running the experiment

```bash
PYTHONPATH=../../modules/ \
chaos run experiment.yaml
```
