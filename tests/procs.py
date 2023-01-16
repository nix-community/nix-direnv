#!/usr/bin/env python3

import subprocess
from typing import List, Union, IO, Any, Optional
from pathlib import Path


_FILE = Union[None, int, IO[Any]]
_DIR = Union[None, Path, str]


def run(
    cmd: List[str],
    text: bool = True,
    check: bool = True,
    cwd: _DIR = None,
    stderr: _FILE = None,
    stdout: _FILE = None,
    env: Optional[dict[str, str]] = None,
) -> subprocess.CompletedProcess:
    if cwd is not None:
        print(f"cd {cwd}")
    print("$ " + " ".join(cmd))
    return subprocess.run(
        cmd, text=text, check=check, cwd=cwd, stderr=stderr, stdout=stdout, env=env
    )
