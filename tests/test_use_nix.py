import os
import subprocess
import sys
import unittest
from typing import Optional

from direnv_project import DirenvProject
from procs import run


def direnv_exec(
    direnv_project: DirenvProject, cmd: str, env: Optional[dict[str, str]] = None
) -> None:
    args = ["direnv", "exec", str(direnv_project.dir), "sh", "-c", cmd]
    print("$ " + " ".join(args))
    out = run(
        args,
        stderr=subprocess.PIPE,
        stdout=subprocess.PIPE,
        check=False,
        cwd=direnv_project.dir,
        env=env,
    )
    sys.stdout.write(out.stdout)
    sys.stderr.write(out.stderr)
    assert out.returncode == 0
    assert "OK\n" == out.stdout
    assert "renewed cache" in out.stderr


def test_attrs(direnv_project: DirenvProject) -> None:
    direnv_project.setup_envrc("use nix -A subshell")
    direnv_exec(direnv_project, "echo $THIS_IS_A_SUBSHELL")


def test_no_nix_path(direnv_project: DirenvProject) -> None:
    direnv_project.setup_envrc("use nix --argstr someArg OK")
    env = os.environ.copy()
    del env["NIX_PATH"]
    direnv_exec(direnv_project, "echo $SHOULD_BE_SET", env=env)


def test_args(direnv_project: DirenvProject) -> None:
    direnv_project.setup_envrc("use nix --argstr someArg OK")
    direnv_exec(direnv_project, "echo $SHOULD_BE_SET")


def test_no_files(direnv_project: DirenvProject) -> None:
    direnv_project.setup_envrc("use nix -p hello")
    out = run(
        ["direnv", "status"],
        stderr=subprocess.PIPE,
        stdout=subprocess.PIPE,
        check=False,
        cwd=direnv_project.dir,
    )
    assert out.returncode == 0
    assert 'Loaded watch: "."' not in out.stdout


if __name__ == "__main__":
    unittest.main()
