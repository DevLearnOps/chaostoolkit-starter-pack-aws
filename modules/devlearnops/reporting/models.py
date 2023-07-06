from typing import List


class Activity:
    def __init__(self, data):
        self.name = data.get("name", "undefined")
        self.type = data.get("type")
        self.tolerance = data.get("tolerance")
        self.provider = data.get("provider")


class ActivityExecution:
    def __init__(self, data):
        self.activity: Activity = data.get("activity")
        self.output = data.get("output")
        self.exception = data.get("exception")
        self.start = data.get("start")
        self.end = data.get("end")
        self.duration = data.get("duration")
        self.status = data.get("status")
        self.tolerance_met = data.get("tolerance_met")

    @property
    def is_failed(self) -> bool:
        """Returns True if the activity has failed"""
        if self.activity.type == "probe":
            return self.status != "succeeded" or self.tolerance_met is not True

        return self.status != "succeeded"

    def fail_summary(self):
        """Generates a concise fail summary of the activity for notification purposes"""
        if not self.is_failed:
            return None

        if self.activity.type == "probe":
            summary = f"Probe [{self.activity.name}] failed verification:"
            summary += f"\n  tolerance verification met: {self.tolerance_met}"
        else:
            summary = f"Activity [{self.activity.name}] failed to complete"

        exception = self.exception or []
        if exception:
            exception_text = "    ".join(exception)
            summary += f"\n  exception: {exception_text}"

        if self.output:
            summary += f"\n  output: {str(self.output)}"

        return summary


class SteadyState:
    def __init__(self, data):
        self.steady_state_met = data.get("steady_state_met")
        self.probes: List[ActivityExecution] = data.get("probes")

    def fail_summary(self):
        """Generates a concise fail summary of the verification for notification purposes"""
        if self.steady_state_met is not True:
            summaries = [activity.fail_summary() for activity in self.probes]
            return "\n".join([summary for summary in summaries if summary is not None])


class SteadyStates:
    def __init__(self, data):
        self.steady_state_met = data.get("steady_state_met")
        self.before: SteadyState = data.get("before")
        self.after: SteadyState = data.get("after")
        self.during: List[SteadyState] = data.get("during")

    def fail_summary(self):
        """Generates a concise fail summary of all verifications for notification purposes"""
        summary = []
        before_summaries = self.before.fail_summary() if self.before else ""
        after_summaries = self.after.fail_summary() if self.after else ""
        during_summaries = []
        if self.during:
            for steady_state in self.during:
                result = steady_state.fail_summary()
                if result:
                    during_summaries.append(result)

        if before_summaries:
            content = "# Failed Steady-State Verifications Before Experiment:\n\n"
            content += before_summaries
            summary.append(content)

        if after_summaries:
            content = "# Failed Steady-State Verifications After Experiment:\n\n"
            content += after_summaries
            summary.append(content)

        if during_summaries:
            content = (
                "# Failed Continuous Steady-State Verifications for Experiment:\n\n"
            )
            content += "\n".join(during_summaries)
            summary.append(content)

        return summary


class Experiment:
    def __init__(self, data):
        self.title = data.get("title")
        self.description = data.get("description")


class Journal:
    def __init__(self, data):
        self.experiment: Experiment = data.get("experiment")
        self.start = data.get("start")
        self.end = data.get("end")
        self.duration = data.get("duration")
        self.deviated = data.get("deviated")
        self.status = data.get("status")
        self.steady_states: SteadyStates = data.get("steady_states")
        self.run: List[ActivityExecution] = data.get("run")
        self.rollbacks: List[ActivityExecution] = data.get("rollbacks")

    def fail_summary(self):
        """Generates a concise fail summary of steady state verifications for notification purposes"""

        summary = self.steady_states.fail_summary()

        if self.run:
            results = [activity.fail_summary() for activity in self.run]
            run_summaries = "\n".join([item for item in results if item is not None])
            if run_summaries:
                content = "# Failed Expeirment Method Activities\n\n"
                content += run_summaries
                summary.append(content)

        if self.rollbacks:
            results = [activity.fail_summary() for activity in self.rollbacks]
            rollback_summaries = "\n".join(
                [item for item in results if item is not None]
            )
            if rollback_summaries:
                content = "# Failed Expeirment Rollbacks Activities\n\n"
                content += rollback_summaries
                summary.append(content)

        return "\n\n".join(summary)
