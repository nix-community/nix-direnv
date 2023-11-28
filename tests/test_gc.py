from __future__ import annotations

import json

import pytest

from .case import TestCase


class TestGc(TestCase):
    def common_test(self) -> None:
        result = self.direnv_exec("hello")
        assert "renewed cache" in result.stderr
        assert "Executing shellHook." in result.stderr

        self.nix_run("store", "gc")

        result = self.direnv_exec("hello")
        assert "using cached dev shell" in result.stderr
        assert "Executing shellHook." in result.stderr

    def common_test_clean(self) -> None:
        self.direnv_exec("hello")
        files = [path for path in (self.path / ".direnv").iterdir() if path.is_file()]
        rcs = [f for f in files if f.match("*.rc")]
        profiles = [f for f in files if not f.match("*.rc")]
        assert len(rcs) == 1, files
        assert len(profiles) == 1, files

    @pytest.mark.parametrize("strict_env", [False, True])
    def test_use_nix(self, strict_env: bool) -> None:
        self.setup_envrc("use nix", strict_env=strict_env)
        self.common_test()

        self.setup_envrc(
            "use nix --argstr shellHook 'echo Executing hijacked shellHook.'",
            strict_env=strict_env,
        )
        self.common_test_clean()

    def _parse_inputs(self, inputs: dict) -> list:
        paths = [inputs["path"]]
        for xinput in inputs["inputs"].values():
            paths.extend(self._parse_inputs(xinput))
        return paths

    @pytest.mark.parametrize("strict_env", [False, True])
    def test_use_flake(self, strict_env: bool) -> None:
        self.setup_envrc("use flake", strict_env=strict_env)
        self.common_test()
        inputs = list((self.path / ".direnv/flake-inputs").iterdir())
        flake_inputs = self._parse_inputs(
            json.loads(
                self.nix_run(
                    "flake", "archive", "--json", "--no-write-lock-file"
                ).stdout
            )
        )
        # should only contain our flake-utils flake
        assert len(inputs) == len(flake_inputs)
        for symlink in inputs:
            assert symlink.is_dir()

        self.setup_envrc("use flake --impure", strict_env=strict_env)
        self.common_test_clean()
