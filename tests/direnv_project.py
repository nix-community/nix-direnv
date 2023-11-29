import shutil
import textwrap
from dataclasses import dataclass
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Iterator

import pytest

from .procs import run


@dataclass
class DirenvProject:
    directory: Path
    nix_direnv: Path

    @property
    def envrc(self) -> Path:
        return self.directory / ".envrc"

    def setup_envrc(self, content: str, strict_env: bool) -> None:
        text = textwrap.dedent(
            f"""
        {'strict_env' if strict_env else ''}
        source {self.nix_direnv}
        {content}
        """
        )
        self.envrc.write_text(text)
        run(["direnv", "allow"], cwd=self.directory)


@pytest.fixture
def direnv_project(test_root: Path, project_root: Path) -> Iterator[DirenvProject]:
    """
    Setups a direnv test project
    """
    with TemporaryDirectory() as _dir:
        directory = Path(_dir) / "proj"
        shutil.copytree(test_root / "testenv", directory)
        shutil.copyfile(project_root / "flake.nix", directory / "flake.nix")
        shutil.copyfile(project_root / "flake.lock", directory / "flake.lock")
        shutil.copyfile(project_root / "treefmt.nix", directory / "treefmt.nix")
        nix_direnv = project_root / "direnvrc"

        c = DirenvProject(Path(directory), nix_direnv)
        try:
            yield c
        finally:
            pass
