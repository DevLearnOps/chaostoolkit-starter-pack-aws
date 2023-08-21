# RDS Instance Reboot

This experiment simulates the reboot of a RDS instance. This can help determine if your instance is able to recover in a timely manner.

## Business Value

With this experiment we want to make sure that if an RDS instance is restarted our services will continue serving requests without impacting user traffic.
Rebooting an instance could be required as part of a maintenance task or triggered by auto scaling.
Regardless, we want to make sure our application are resilient to this even and can recreate a stable connection to the database after a restart.

## System Requirements

**Python Packages**

* chaostoolkit-aws

## Running the experiment

```bash
PYTHONPATH=../../modules/ \
chaos run experiment.yaml
```
