#!/usr/bin/env python2

from tempfile import TemporaryDirectory
import os
import subprocess
from pathlib import Path
import shutil
import unittest


TEST_ROOT = Path(__file__).resolve().parent


class IntegrationTest(unittest.TestCase):
    def setUp(self) -> None:
        self.env = os.environ.copy()
        self.dir = TemporaryDirectory()
        self.env["HOME"] = str(self.dir.name)
        self.testenv = Path(self.dir.name).joinpath("testenv")
        shutil.copytree(TEST_ROOT.joinpath("testenv"), self.testenv)
        direnvrc = str(TEST_ROOT.parent.joinpath("direnvrc"))
        with open(self.testenv.joinpath(".envrc"), "w") as f:
            f.write(f"source {direnvrc}\n")
            f.write(f"use nix")

    def test_direnv(self) -> None:
        subprocess.run(
            ["direnv", "allow"], cwd=str(self.testenv), env=self.env, check=True
        )
        subprocess.run(
            ["direnv", "exec", str(self.testenv), "hello"], env=self.env, check=True
        )

    def tearDown(self) -> None:
        self.dir.cleanup()


if __name__ == "__main__":
    unittest.main()
