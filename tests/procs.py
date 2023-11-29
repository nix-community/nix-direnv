import logging
import subprocess
from pathlib import Path
from typing import IO, Any

_FILE = None | int | IO[Any]
_DIR = None | Path | str

log = logging.getLogger(__name__)


def run(
    cmd: list[str],
    text: bool = True,
    check: bool = True,
    cwd: _DIR = None,
    stderr: _FILE = None,
    stdout: _FILE = None,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess:
    if cwd is not None:
        log.debug(f"cd {cwd}")
    log.debug("$ " + " ".join(cmd))
    return subprocess.run(
        cmd, text=text, check=check, cwd=cwd, stderr=stderr, stdout=stdout, env=env
    )
