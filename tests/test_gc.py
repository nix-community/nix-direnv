#!/usr/bin/env python2

import sys
import subprocess
import unittest

from procs import run
from direnv_project import DirenvProject


def common_test(direnv_project: DirenvProject) -> None:
    run(["nix-collect-garbage"])

    testenv = str(direnv_project.dir)

    out1 = run(
        ["direnv", "exec", testenv, "hello"],
        stderr=subprocess.PIPE,
        check=False,
        cwd=direnv_project.dir,
    )
    sys.stderr.write(out1.stderr)
    assert out1.returncode == 0
    assert "renewed cache" in out1.stderr
    assert "Executing shellHook." in out1.stderr

    run(["nix-collect-garbage"])

    out2 = run(
        ["direnv", "exec", testenv, "hello"],
        stderr=subprocess.PIPE,
        check=False,
        cwd=direnv_project.dir,
    )
    sys.stderr.write(out2.stderr)
    assert out1.returncode == 0
    assert "using cached dev shell" in out2.stderr
    assert "Executing shellHook." in out2.stderr


def test_use_nix(direnv_project: DirenvProject) -> None:
    direnv_project.setup_envrc("use nix")
    common_test(direnv_project)


def test_use_flake(direnv_project: DirenvProject) -> None:
    direnv_project.setup_envrc("use flake")
    common_test(direnv_project)
    inputs = list((direnv_project.dir / ".direnv/flake-inputs").iterdir())
    # should only contain our flake-utils flake
    if len(inputs) != 3:
        run(["nix", "flake", "archive", "--json"], cwd=direnv_project.dir)
        print(inputs)
    assert len(inputs) == 3
    for symlink in inputs:
        assert symlink.is_dir()


if __name__ == "__main__":
    unittest.main()
