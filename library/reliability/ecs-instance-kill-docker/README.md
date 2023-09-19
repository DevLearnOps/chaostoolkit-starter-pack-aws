# Experiment: ECS Instance Kill Docker Engine

When the Docker Engine terminates abruptly, container instances that provide capacity for
ECS clusters should self-heal and restart the `ecs-agent`.

## Business Value

When we self-manage container instances to provision capacity for our ECS services, we can expect
them to fail suddenly and without warning. When that happens we need to be confident that the system
can self-heal in a short amount of time.
Also this experiment can be useful to verify that application circuit breakers and other resiliency patterns
are implemented to minimize the impact on user traffic while instances are recovering.

## System Requirements

**Additional Software**

* Grafana K6

**Python Packages**

* chaostoolkit-addons
* chaostoolkit-aws
* chaostoolkit-grafana


## Running The Experiment

Steps to execute this experiment

```bash
export PYTHONPATH=../../../modules/
chaos run \
    --rollback-strategy always \
    --hypothesis-strategy continuously \
    --hypothesis-frequency 120 \
    --fail-fast \
    experiment.yaml
```
