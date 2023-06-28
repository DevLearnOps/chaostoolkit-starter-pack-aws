# Experiment: Service Scale-Out

Verify that ECS service autoscaling policies can scale-out tasks under load within a certain time and with no service degradation.
The experiment manually sets the number of desired containers while the service is under load and waits until the service to complete the scaling operation.

## Business Value

Make sure services can scale-out effectively to handle additional load and with no significant degradation for users.

## System Requirements

**Additional Software**

* Grafana K6

**Python Packages**

* chaostoolkit-aws
* chaostoolkit-grafana

## Running the experiment

```bash
PYTHONPATH=../../modules/ \
chaos run experiment.yaml
```
