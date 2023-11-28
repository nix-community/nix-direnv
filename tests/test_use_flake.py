from __future__ import annotations

import pytest

from .case import TestCase


class TestUseFlake(TestCase):
    @pytest.mark.parametrize("strict_env", [False, True])
    def test_usage(self, strict_env: bool) -> None:
        self.setup_envrc("use flake", strict_env=strict_env)
        result = self.direnv_exec("true")
        assert "renewed cache" in result.stderr
        result = self.direnv_exec("true")
        assert "using cached dev shell" in result.stderr
        self.run("touch", ".envrc")
        result = self.direnv_exec("true")
        assert "renewed cache" in result.stderr

    @pytest.mark.parametrize("strict_env", [False, True])
    def test_bad_usage(self, strict_env: bool) -> None:
        self.setup_envrc("use flake --impure", strict_env=strict_env)
        result = self.direnv_exec("true")
        must_be_flake = "the first argument must be a flake expression"
        did_you_mean = "did you mean 'use flake . --impure'?"
        assert must_be_flake in result.stderr
        assert did_you_mean in result.stderr
        self.setup_envrc("use flake --impure .", strict_env=strict_env)
        result = self.direnv_exec("true")
        assert must_be_flake in result.stderr
        assert did_you_mean not in result.stderr

    @pytest.mark.parametrize("strict_env", [False, True])
    def test_env_set(self, strict_env: bool) -> None:
        self.setup_envrc("use flake", strict_env=strict_env)
        result = self.assert_direnv_var("IS_SET")
        assert "renewed cache" in result.stderr
