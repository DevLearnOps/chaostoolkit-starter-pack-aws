# Experiment: ECS Service Max Capacity Alerting

Simulate an ECS service reaching its max allowed container count.
The experiment validates that upon reaching its maximum allowed container count, a notification is sent to an SNS topic and successfully received.

## Business Value

Make sure the registered alarms actually notify our SRE team when a service reaches max capacity, giving us the chance to evaluate whether we need to adjust the scaling policy or the event is just a symptom of a larger issue.

## System Requirements

**Python Packages**

* chaostoolkit-aws
* chaostoolkit-terraform

## Running the experiment

```bash
PYTHONPATH=../../modules/ \
chaos run \
    --hypothesis-strategy after-method-only \
    --rollback-strategy always \
    experiment.yaml
```
