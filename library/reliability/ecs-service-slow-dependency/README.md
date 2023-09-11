# Experiment: Slow ECS Service Dependency

Simulates a high latency on a service downstream dependency.

## Business Value

When a minor downstream dependency of a service runs with increased latency this should not have significant impact to our users.

## System Requirements

**Additional Software**

* Grafana K6

**Python Packages**

* chaostoolkit-aws
* chaostoolkit-grafana
* chaostoolkit-terraform

## Running the experiment

```bash
PYTHONPATH=../../modules/ \
chaos run \
    --hypothesis-strategy after-method-only \
    --rollback-strategy always \
    experiment.yaml
```
