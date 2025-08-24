from pathlib import Path

import pytest

pytest_plugins = [
    "tests.direnv_project",
    "tests.root",
]


@pytest.fixture(autouse=True)
def _cleanenv(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    # so direnv doesn't touch $HOME
    monkeypatch.setenv("HOME", str(tmp_path / "home"))
    # so direnv allow state writes under tmp HOME
    monkeypatch.delenv("XDG_DATA_HOME", raising=False)
    # so direnv does not pick up user customization
    monkeypatch.delenv("XDG_CONFIG_HOME", raising=False)
