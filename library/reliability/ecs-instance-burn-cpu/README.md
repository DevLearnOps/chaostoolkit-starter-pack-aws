# Experiment: ECS Instance Burn CPU

When CPU stressors are introduced to ECS container instances it should not have a negative
effect on user experience other than an understandable additional request latency.

## Business Value

When we provision compute capacity for ECS clusters using container instances on EC2 we need
to take care that nodes are resilient and can always support our workloads.
With this experiment we want simulate a scenario when the underlying instances executing
our application containers experience unusually high CPU utilization.


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
