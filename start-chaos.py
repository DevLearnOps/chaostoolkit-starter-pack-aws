import configparser
import os
import subprocess

import click


def _parse_var_overrides(overrides_conf):
    if not overrides_conf:
        return {}

    overrides = {}

    for var_string in overrides_conf.split("\n"):
        if var_string.strip():
            key, value = var_string.split(":", maxsplit=1)
            overrides[key.strip()] = value.strip()

    return overrides


class ExperimentConfig:
    def __init__(self):
        self.experiment_path = "experiment.yaml"
        self.base_path = "."
        self.rollback_strategy = "always"
        self.hypothesis_strategy = None
        self.hypothesis_frequency = None
        self.fail_fast = None
        self.var_files = []
        self.var_overrides = {}

    def read(self, config_file, context: str = None):
        if not os.path.isfile(config_file):
            raise ValueError(
                f"Configuration file {config_file} was not found or is not a file"
            )
        config = configparser.ConfigParser()
        config.read(config_file)

        self.base_path = os.path.dirname(config_file)

        if context and context not in config.sections():
            raise ValueError(
                f"Malformed configuration file. File does not contain [{context}] section."
            )
        chaos_conf = config[context] if context else config["DEFAULT"]

        self.experiment_path = chaos_conf.get(
            "experiment_path", fallback=self.experiment_path
        )

        self.rollback_strategy = chaos_conf.get(
            "rollback_strategy", fallback=self.rollback_strategy
        )
        self.hypothesis_strategy = chaos_conf.get(
            "hypothesis_strategy", fallback=self.hypothesis_strategy
        )
        self.hypothesis_frequency = chaos_conf.get(
            "hypothesis_frequency", fallback=self.hypothesis_frequency
        )
        self.fail_fast = chaos_conf.get("fail_fast", fallback=self.fail_fast)

        var_files_list = (
            chaos_conf.get("var_files", fallback="").replace("\n", "").strip()
        )
        for file in var_files_list.split(","):
            if file.strip():
                self.var_files.append(file.strip())

        self.var_overrides = _parse_var_overrides(
            chaos_conf.get("var_overrides", fallback="")
        )

        return self

    def get_options(self):
        opts = []
        if self.rollback_strategy:
            opts.extend(
                [
                    "--rollback-strategy",
                    self.rollback_strategy,
                ]
            )
        if self.hypothesis_strategy:
            opts.extend(
                [
                    "--hypothesis-strategy",
                    self.hypothesis_strategy,
                ]
            )
        if self.hypothesis_frequency:
            opts.extend(
                [
                    "--hypothesis-frequency",
                    self.hypothesis_frequency,
                ]
            )
        if self.fail_fast is True:
            opts.append("--fail-fast")

        for var_file in self.var_files:
            opts.extend(["--var-file", var_file])

        for key, value in self.var_overrides.items():
            opts.extend(["--var", f"{key}={value}"])

        return opts

    def get_experiment_path(self):
        experiment_full_path = os.path.join(self.base_path, self.experiment_path)
        if not os.path.isfile(experiment_full_path):
            raise ValueError(
                f"Could not locate experiment file in path '{experiment_full_path}'"
            )
        return self.experiment_path


@click.command()
@click.option(
    "--verbose",
    "-v",
    is_flag=True,
    show_default=True,
    default=False,
    help="Display debug level traces.",
)
@click.option(
    "--context",
    required=False,
    help="The execution context for the experiment",
)
@click.argument("config-file", envvar="CHAOS_CONFIG_FILE", type=click.Path(exists=True))
def cli(verbose: bool, context: str, config_file: str):
    """
    Cli to start a chaos experiment from a configuration definition
    """

    config = ExperimentConfig().read(config_file, context=context)

    command = ["chaos", "run"]
    if verbose:
        command.insert(1, "--verbose")

    command.extend(config.get_options())

    command.append(config.get_experiment_path())
    print(f"> {' '.join(command)}")

    result = subprocess.run(
        command,
        cwd=config.base_path,
        shell=False,
        capture_output=False,
        check=False,
    )

    print(f"\nProcess exited with code: {result.returncode}")


if __name__ == "__main__":
    cli(auto_envvar_prefix="CHAOS")  # pylint: disable=no-value-for-parameter
