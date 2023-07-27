# RDS Failover DB Cluster

This experiment simulates the failover of a DB cluster. This can help determine if your DB is able to recover from a failover.

## System Requirements

**Python Packages**

* chaostoolkit-aws

## Running the experiment

```bash
PYTHONPATH=../../modules/ \
chaos run experiment.yaml
```
