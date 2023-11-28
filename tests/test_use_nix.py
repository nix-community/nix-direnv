from __future__ import annotations

import os

import pytest

from .case import TestCase


class TestUseNix(TestCase):
    @pytest.mark.parametrize("strict_env", [False, True])
    def test_attrs(self, strict_env: bool) -> None:
        self.setup_envrc("use nix -A subshell", strict_env=strict_env)
        self.assert_direnv_var("THIS_IS_A_SUBSHELL")

    @pytest.mark.parametrize("strict_env", [False, True])
    def test_with_nix_path(self, strict_env: bool) -> None:
        if (nix_path := os.environ.get("NIX_PATH")) is None:
            pytest.skip("no parent NIX_PATH")
        else:
            self.setup_envrc(
                "use nix --argstr someArg OK", strict_env=strict_env, NIX_PATH=nix_path
            )
            self.assert_direnv_var("SHOULD_BE_SET", NIX_PATH=nix_path)

    @pytest.mark.parametrize("strict_env", [False, True])
    def test_args(self, strict_env: bool) -> None:
        self.setup_envrc("use nix --argstr someArg OK", strict_env=strict_env)
        self.assert_direnv_var("SHOULD_BE_SET")

    @pytest.mark.parametrize("strict_env", [False, True])
    def test_no_files(self, strict_env: bool) -> None:
        self.setup_envrc("use nix -p hello", strict_env=strict_env)
        result = self.direnv_run("status")
        assert 'Loaded watch: "."' not in result.stdout
