# Experiment: ECS Service AZ Failure

Simulates Availability Zone failure for a running ECS service.

## Business Value

With this experiment we want to assess the impact a single AZ failure has
on a running ECS service. To make sure we are resilient to this type of failure,
the service should be able to continue serving traffic throughout the duration of
the outage. It's still acceptable for some requests to fail when the AZ is no longer
available, though this effect should resolve itself in a short amount of time.

## System Requirements

**Additional Software**

* Grafana K6
* [AWS Fail AZ](https://github.com/mcastellin/aws-fail-az)

**Python Packages**

* chaostoolkit-aws
* chaostoolkit-grafana

## Running the experiment

```bash
PYTHONPATH=../../modules/ \
chaos run \
    --rollback-strategy always \
    experiment.yaml
```
