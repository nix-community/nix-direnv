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
    assert out2.returncode == 0
    assert "using cached dev shell" in out2.stderr
    assert "Executing shellHook." in out2.stderr


def common_test_clean(direnv_project: DirenvProject) -> None:
    testenv = str(direnv_project.dir)

    out3 = run(
        ["direnv", "exec", testenv, "hello"],
        stderr=subprocess.PIPE,
        check=False,
        cwd=direnv_project.dir,
    )
    sys.stderr.write(out3.stderr)

    files = [
        path for path in (direnv_project.dir / ".direnv").iterdir() if path.is_file()
    ]
    rcs = [f for f in files if f.match("*.rc")]
    profiles = [f for f in files if not f.match("*.rc")]
    if len(rcs) != 1 or len(profiles) != 1:
        print(files)
    assert len(rcs) == 1
    assert len(profiles) == 1


def test_use_nix(direnv_project: DirenvProject) -> None:
    direnv_project.setup_envrc("use nix")
    common_test(direnv_project)

    direnv_project.setup_envrc(
        "use nix --argstr shellHook 'echo Executing hijacked shellHook.'"
    )
    common_test_clean(direnv_project)


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

    direnv_project.setup_envrc("use flake --impure")
    common_test_clean(direnv_project)


if __name__ == "__main__":
    unittest.main()
