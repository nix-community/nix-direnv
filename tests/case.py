from __future__ import annotations

import functools
import logging
import os
import shutil
import subprocess
import textwrap
from pathlib import Path

import pytest

CMD = Path | str

log = logging.getLogger(__name__)

TEST_ROOT = Path(__file__).parent

PROJECT_ROOT = TEST_ROOT.parent

NIX_DIRENV = PROJECT_ROOT / "direnvrc"


class TestCase:
    @pytest.fixture(autouse=True)
    def _setup(self, tmp_path: Path) -> None:
        self.root = tmp_path
        log.debug(f"path: {self.root}")

    @functools.cached_property
    def home(self) -> Path:
        return self.root / "home"

    @functools.cached_property
    def path(self) -> Path:
        path = self.root / "cwd"
        shutil.copytree(TEST_ROOT / "testenv", path)
        return path

    def _log_output(
        self,
        result: subprocess.CompletedProcess | subprocess.CalledProcessError,
        errlevel: str = "debug",
    ) -> None:
        for out in ("stdout", "stderr"):
            text = getattr(result, out).strip()
            setattr(result, out, text)
            if text:
                getattr(log, errlevel if out == "stderr" else "debug")(
                    f"{out[3:]}:{os.linesep if os.linesep in text else ' '}{text}"
                )

    def run(
        self,
        *cmd: CMD,
        **env: str,
    ) -> subprocess.CompletedProcess:
        env = dict(PATH=os.environ["PATH"], HOME=str(self.home)) | env
        command = list(map(str, cmd))
        log.debug(f"$ {subprocess.list2cmdline(command)}")
        try:
            result = subprocess.run(
                command,
                capture_output=True,
                check=True,
                text=True,
                cwd=self.path,
                env=env,
            )
        except subprocess.CalledProcessError as exc:  # pragma: no cover
            self._log_output(exc, errlevel="error")
            raise
        self._log_output(result)
        return result

    def nix_run(self, *cmd: CMD, **env: str) -> subprocess.CompletedProcess:
        return self.run("nix", *cmd, **env)

    def direnv_run(self, *cmd: CMD, **env: str) -> subprocess.CompletedProcess:
        return self.run("direnv", *cmd, **env)

    def direnv_exec(self, *cmd: CMD, **env: str) -> subprocess.CompletedProcess:
        return self.run("direnv", "exec", ".", *cmd, **env)

    def direnv_var(self, name: str, **env: str) -> subprocess.CompletedProcess:
        return self.direnv_exec("sh", "-c", f"echo -n ${name}", **env)

    def setup_envrc(
        self, content: str, strict_env: bool, **env: str
    ) -> subprocess.CompletedProcess:
        text = textwrap.dedent(
            f"""
        {'strict_env' if strict_env else ''}
        source {NIX_DIRENV}
        {content}
        """,
        )
        (self.path / ".envrc").write_text(text.strip())
        return self.direnv_run("allow", **env)

    def assert_direnv_var(self, name: str, **env: str) -> subprocess.CompletedProcess:
        result = self.direnv_var(name, **env)
        assert result.stdout == "OK"
        assert "renewed cache" in result.stderr
        return result
