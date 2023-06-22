# Service Manual Scaling

This experiment simulates a manual update to the desired count of istances of your service. This can help determine if your infrastructure is able to scale in a timely manner.

## System Requirements

**Python Packages**

* chaostoolkit-aws

## Running the experiment

```bash
PYTHONPATH=../../modules/ \
chaos run experiment.yaml
```
