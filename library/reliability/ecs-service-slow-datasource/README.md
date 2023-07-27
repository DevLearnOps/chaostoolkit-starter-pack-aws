# Experiment: Slow Service Datasource

Simulates a increase latency on the main service datasource

## Business Value

When a service is experiencing high traffic it is normal for its main datasource to respond with increased latency due to resource
exhaustion. In this situation we want our service to behave normally and keep processing requests without crashing.
This test gives engineers the confidence that autoscaling policies and resource allocations are configured correctly to handle a
high traffic situation.

## System Requirements

**Additional Software**

* Grafana K6

**Python Packages**

* chaostoolkit-aws
* chaostoolkit-grafana
* chaostoolkit-terraform
* chaostoolkit-aws-attacks

## Running the experiment

```bash
PYTHONPATH=../../modules/ \
chaos run \
    --hypothesis-strategy continuously \
    --hypothesis-frequency 30 \
    --fail-fast \
    --rollback-strategy always \
    experiment.yaml
```
