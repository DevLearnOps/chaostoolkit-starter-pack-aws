# Experiment: Name your experiment

Short experiment description

## Business Value

Explain the value of running this experiment


## System Requirements

**Additional Software**

* some software
* some other software

**Python Packages**

* chaostoolkit-aws
* chaostoolkit-grafana
* another-package


## Running The Experiment

Steps to execute this experiment

```bash
export PYTHONPATH=../../../modules/
chaos run \
    --rollback-strategy always \
    experiment.yaml
```
