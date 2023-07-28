# Experiment: Slow ECS Service AZ Failure

Simulates Availability Zone failure for a running ECS service

## Business Value

TODO

## System Requirements

**Additional Software**

* Grafana K6

**Python Packages**

* chaostoolkit-aws
* chaostoolkit-grafana
* chaostoolkit-aws-attacks

## Running the experiment

```bash
PYTHONPATH=../../modules/ \
chaos run \
    --rollback-strategy always \
    experiment.yaml
```
