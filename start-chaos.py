import configparser
import json
import os
import subprocess
from datetime import datetime
from signal import SIGINT, Signals, signal

import boto3
import click
from devlearnops import sanitize_name_for_path


def _parse_var_overrides(overrides_conf):
    if not overrides_conf:
        return {}

    overrides = {}

    for var_string in overrides_conf.split("\n"):
        if var_string.strip():
            key, value = var_string.split("=", maxsplit=1)
            overrides[key.strip()] = value.strip()

    return overrides


def void_handler(sig, *args):
    """
    An empty signal handler to let the ChaosToolkit subprocess handle the
    exit signal
    """
    print(f"Received signal {Signals(sig).name}.")


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


def _upload_journal_and_logs(journals_bucket, journal_path, ctk_logs_path) -> str:
    boto_session = boto3.session.Session()

    if not os.path.isfile(journal_path):
        print(f"Could not find journal file {journal_path}. Unable to upload to S3.")
        return None

    with open(journal_path, mode="r", encoding="utf-8") as file:
        journal_data = json.load(file)

    start_time = datetime.strptime(journal_data.get("start"), "%Y-%m-%dT%H:%M:%S.%f")
    sanitized_name = sanitize_name_for_path(
        journal_data.get("experiment", {}).get("title", "undefined"),
        max_len=50,
    )
    upload_path = start_time.strftime("%Y%m%d_%H%M%S") + f"_{sanitized_name}"
    print(
        f"Uploading experiment journal and logs to [s3://{journals_bucket}/{upload_path}/]"
    )

    s3_client = boto_session.client("s3")
    with open(journal_path, mode="rb") as binary_file:
        s3_client.upload_fileobj(
            binary_file,
            Bucket=journals_bucket,
            Key=f"{upload_path}/journal.json",
        )
    with open(ctk_logs_path, mode="rb") as binary_file:
        s3_client.upload_fileobj(
            binary_file,
            Bucket=journals_bucket,
            Key=f"{upload_path}/chaostoolkit.log",
        )

    return upload_path


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
@click.option(
    "--journals-bucket",
    required=False,
    help="The S3 bucket to upload journal files after experiment execution",
)
@click.argument("config-file", envvar="CHAOS_CONFIG_FILE", type=click.Path(exists=True))
def cli(verbose: bool, context: str, journals_bucket: str, config_file: str):
    """
    Cli to start a chaos experiment from a configuration definition
    """

    config = ExperimentConfig().read(config_file, context=context)

    command = ["chaos", "--no-version-check", "run"]
    if verbose:
        command.insert(1, "--verbose")

    command.extend(config.get_options())

    command.append(config.get_experiment_path())
    print(f"> {' '.join(command)}")

    with subprocess.Popen(
        command,
        cwd=config.base_path,
        stdout=None,
        stdin=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    ) as process:
        signal(SIGINT, void_handler)

        process.communicate()
        return_code = process.returncode

    print(f"\nProcess exited with code: {return_code}")

    if journals_bucket:
        _upload_journal_and_logs(
            journals_bucket,
            os.path.join(config.base_path, "journal.json"),
            os.path.join(config.base_path, "chaostoolkit.log"),
        )


if __name__ == "__main__":
    cli(auto_envvar_prefix="CHAOS")  # pylint: disable=no-value-for-parameter
