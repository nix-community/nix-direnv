#!/usr/bin/env python2

import sys
import subprocess
import unittest

from procs import run
from direnv_project import DirenvProject


def direnv_exec(direnv_project: DirenvProject, cmd: str) -> None:
    out = run(
        ["direnv", "exec", str(direnv_project.dir), "sh", "-c", cmd],
        stderr=subprocess.PIPE,
        stdout=subprocess.PIPE,
        check=False,
        cwd=direnv_project.dir,
    )
    sys.stdout.write(out.stdout)
    sys.stderr.write(out.stderr)
    assert out.returncode == 0
    assert "OK\n" == out.stdout
    assert "renewed cache" in out.stderr


def test_attrs(direnv_project: DirenvProject) -> None:
    direnv_project.setup_envrc("use nix -A subshell")
    direnv_exec(direnv_project, "echo $THIS_IS_A_SUBSHELL")


def test_args(direnv_project: DirenvProject) -> None:
    direnv_project.setup_envrc("use nix --argstr someArg OK")
    direnv_exec(direnv_project, "echo $SHOULD_BE_SET")


def test_no_files(direnv_project: DirenvProject) -> None:
    direnv_project.setup_envrc("use nix -p hello")
    direnv_exec(direnv_project, "hello")


if __name__ == "__main__":
    unittest.main()
