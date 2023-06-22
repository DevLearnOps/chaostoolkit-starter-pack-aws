# Experiment: Service Max Capacity Alerting

This experiment simulates an ECS service reaching its max allowed container count.
The experiment helps validate that upon reaching its maximum allowed container count, a notification is sent to an SNS topic and successfully recieved.

## System Requirements

**Additional Software**

* Grafana K6

**Python Packages**

* chaostoolkit-aws
* chaostoolkit-grafana

## Running the experiment

```bash
PYTHONPATH=../../modules/ \
chaos run --hypothesis-strategy after-method-only experiment.yaml
```
