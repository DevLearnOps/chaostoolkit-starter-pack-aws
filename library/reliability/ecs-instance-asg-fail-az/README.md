# Experiment: ECS Instance AutoScaling Group AZ Failure

Simulates Availability Zone failure for the autoscaling group provisioning capacity to an ECS service.

## Business Value

When we provision compute capacity for ECS clusters using container instances on EC2 we need
to take care that nodes are resilient and can always support our workloads.
With this experiment we want to learn what consequences a complete failure of an availability zone
has on the auto scaling group provisioning resources for containers running on ECS.

## System Requirements

**Additional Software**

* Grafana K6
* [AWS Fail AZ][https://github.com/mcastellin/aws-fail-az]

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
