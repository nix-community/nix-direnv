#!/usr/bin/env python2

from tempfile import TemporaryDirectory
import os
import sys
import subprocess
from pathlib import Path
import shutil
import unittest
from typing import List


TEST_ROOT = Path(__file__).resolve().parent
RENEWED_MESSAGE = "renewed cache"
CACHED_MESSAGE = "using cached dev shell"


def run(cmd: List[str], **kwargs) -> subprocess.CompletedProcess:
    print("$ " + " ".join(cmd))
    return subprocess.run(cmd, **kwargs)


class TestBaseNamespace:
    """Nested so test discovery doesn't run the base class tests directly."""

    class TestBase(unittest.TestCase):
        env: dict
        dir: TemporaryDirectory
        testenv: Path
        direnvrc: str
        direnvrc_command: str
        out1: subprocess.CompletedProcess
        out2: subprocess.CompletedProcess

        @classmethod
        def setUpClass(cls) -> None:
            cls.env = os.environ.copy()
            cls.dir = TemporaryDirectory()
            cls.env["HOME"] = str(cls.dir.name)
            cls.testenv = Path(cls.dir.name).joinpath("testenv")
            shutil.copytree(TEST_ROOT.joinpath("testenv"), cls.testenv)
            cls.direnvrc = str(TEST_ROOT.parent.joinpath("direnvrc"))

            with open(cls.testenv.joinpath(".envrc"), "w") as f:
                f.write(f"source {cls.direnvrc}\n{cls.direnvrc_command}")

            run(["direnv", "allow"], cwd=str(cls.testenv), env=cls.env, check=True)

            run(["nix-collect-garbage"], check=True)

            cls.out1 = run(
                ["direnv", "exec", str(cls.testenv), "hello"],
                env=cls.env,
                stderr=subprocess.PIPE,
                text=True,
            )
            sys.stderr.write(cls.out1.stderr)

            run(["nix-collect-garbage"], check=True)

            cls.out2 = run(
                ["direnv", "exec", str(cls.testenv), "hello"],
                env=cls.env,
                stderr=subprocess.PIPE,
                text=True,
            )
            sys.stderr.write(cls.out2.stderr)

        @classmethod
        def tearDownClass(cls) -> None:
            cls.dir.cleanup()

        def test_fresh_shell_message(self) -> None:
            self.assertIn(RENEWED_MESSAGE, self.out1.stderr)

        def test_fresh_shell_shellHook_gets_executed(self) -> None:
            self.assertIn("Executing shellHook.", self.out1.stderr)

        def test_fresh_shell_returncode(self) -> None:
            self.assertEqual(self.out1.returncode, 0)

        def test_cached_shell_message(self) -> None:
            self.assertIn(CACHED_MESSAGE, self.out2.stderr)

        def test_cached_shell_shellHook_gets_executed(self) -> None:
            self.assertIn("Executing shellHook.", self.out2.stderr)

        def test_cached_shell_returncode(self) -> None:
            self.assertEqual(self.out2.returncode, 0)


class NixShellTest(TestBaseNamespace.TestBase):
    direnvrc_command = "use nix"


class FlakeTest(TestBaseNamespace.TestBase):
    direnvrc_command = "use flake"

    def test_gcroot_symlink_created_and_valid(self) -> None:
        inputs = list(self.testenv.joinpath(".direnv/flake-inputs").iterdir())
        # should only contain our flake-utils flake
        if len(inputs) != 3:
            subprocess.run(["nix", "flake", "archive", "--json"], cwd=self.testenv)
            print(inputs)
        self.assertEqual(len(inputs), 3)
        for symlink in inputs:
            self.assertTrue(symlink.is_dir())


if __name__ == "__main__":
    unittest.main()
