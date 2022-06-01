#!/usr/bin/env python3

from dataclasses import dataclass
import shutil
from tempfile import TemporaryDirectory
from typing import Iterator
from pathlib import Path

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
        self.envrc.write_text(
            f"""
source {self.nix_direnv}
{content}
        """
        )
        run(["direnv", "allow"], cwd=self.dir)


@pytest.fixture
def direnv_project(test_root: Path, project_root: Path) -> Iterator[DirenvProject]:
    """
    Setups a direnv test project
    """
    with TemporaryDirectory() as _dir:
        dir = Path(_dir) / "proj"
        shutil.copytree(test_root / "testenv", dir)
        nix_direnv = project_root / "direnvrc"

        c = DirenvProject(Path(dir), nix_direnv)
        try:
            yield c
        finally:
            pass
