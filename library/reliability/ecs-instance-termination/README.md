# Experiment: ECS Instance Termination

When an autoscaling group container instance terminates abrubtly,
ECS clusters should self-heal and re-spawn a new one.

## Business Value

When we self-manage container instances to provision capacity for our ECS services, we can expect
them to fail suddenly and without warning. When that happens we need to be confident that the system
can self-heal in a short amount of time and minimal customer impact.

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
    experiment.yaml
```
