from marshmallow import INCLUDE, Schema, fields, post_load, validate

from .models import (
    Activity,
    ActivityExecution,
    Experiment,
    Journal,
    SteadyState,
    SteadyStates,
)

activity_type_validation = validate.OneOf(["action", "probe"])


class ActivitySchema(Schema):
    """A schema to represent a Chaos Toolkit activity"""

    class Meta:
        unknown = INCLUDE

    name = fields.String(allow_none=True)
    type = fields.String(validate=activity_type_validation)
    tolerance = fields.Raw(allow_none=True)
    provider = fields.Raw(allow_none=True)

    @post_load
    def make_obj(self, data, **kwargs):
        return Activity(data)


class ActivityExecutionSchema(Schema):
    """A schema to represent a Chaos Toolkit activity execution results"""

    class Meta:
        unknown = INCLUDE

    activity = fields.Nested(ActivitySchema)
    output = fields.Raw(allow_none=True)
    exception = fields.List(fields.String())

    start = fields.DateTime()
    end = fields.DateTime()
    duration = fields.TimeDelta()

    status = fields.String()
    tolerance_met = fields.Boolean()

    @post_load
    def make_obj(self, data, **kwargs):
        return ActivityExecution(data)


class SteadyStateSchema(Schema):
    """A schema to represent a Chaos Toolkit experiment steady state verification"""

    class Meta:
        unknown = INCLUDE

    steady_state_met = fields.Boolean()
    probes = fields.List(fields.Nested(ActivityExecutionSchema))

    @post_load
    def make_obj(self, data, **kwargs):
        return SteadyState(data)


class SteadyStatesSchema(Schema):
    """A schema to represent Chaos Toolkit experiment steady states"""

    class Meta:
        unknown = INCLUDE

    steady_state_met = fields.Boolean()
    before = fields.Nested(SteadyStateSchema, allow_none=True)
    after = fields.Nested(SteadyStateSchema, allow_none=True)
    during = fields.List(fields.Nested(SteadyStateSchema), allow_none=True)

    @post_load
    def make_obj(self, data, **kwargs):
        return SteadyStates(data)


class ExperimentSchema(Schema):
    """A schema to represent a Chaos Toolkit experiment"""

    class Meta:
        unknown = INCLUDE

    title = fields.String()
    description = fields.String(allow_none=True)

    @post_load
    def make_obj(self, data, **kwargs):
        return Experiment(data)


class JournalSchema(Schema):
    """A schema to represent a Chaos Toolkit experiment journal"""

    class Meta:
        unknown = INCLUDE

    experiment = fields.Nested(ExperimentSchema)
    start = fields.DateTime()
    end = fields.DateTime()
    duration = fields.TimeDelta()

    deviated = fields.Boolean()
    status = fields.String()

    steady_states = fields.Nested(SteadyStatesSchema)
    run = fields.List(fields.Nested(ActivityExecutionSchema))
    rollbacks = fields.List(fields.Nested(ActivityExecutionSchema))

    @post_load
    def make_obj(self, data, **kwargs):
        return Journal(data)
