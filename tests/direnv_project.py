#!/usr/bin/env python3

import shutil
import textwrap
from dataclasses import dataclass
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Iterator

import pytest
from procs import run


@dataclass
class DirenvProject:
    dir: Path
    nix_direnv: Path

    @property
    def envrc(self) -> Path:
        return self.dir / ".envrc"

    def setup_envrc(self, content: str) -> None:
        text = textwrap.dedent(
            f"""
        source {self.nix_direnv}
        {content}
        """
        )
        self.envrc.write_text(text)
        run(["direnv", "allow"], cwd=self.dir)


@pytest.fixture
def direnv_project(test_root: Path, project_root: Path) -> Iterator[DirenvProject]:
    """
    Setups a direnv test project
    """
    with TemporaryDirectory() as _dir:
        dir = Path(_dir) / "proj"
        shutil.copytree(test_root / "testenv", dir)
        shutil.copyfile(project_root / "flake.nix", dir / "flake.nix")
        shutil.copyfile(project_root / "flake.lock", dir / "flake.lock")
        nix_direnv = project_root / "direnvrc"

        c = DirenvProject(Path(dir), nix_direnv)
        try:
            yield c
        finally:
            pass
