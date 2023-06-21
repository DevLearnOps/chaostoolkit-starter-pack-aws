# Experiment: Service Autoscaling

This experiment simulates a surge in the number of requests to your service. This can help determine if your autoscaling mechanism responds appropriately and scales out the resources to handle the increased load effectively.

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
