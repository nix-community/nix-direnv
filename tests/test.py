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


def run(cmd: List[str], **kwargs) -> subprocess.CompletedProcess:
    print("$ " + " ".join(cmd))
    return subprocess.run(cmd, **kwargs)


def support_flakes() -> bool:
    cmd = [
        "nix-instantiate",
        "--json",
        "--eval",
        "--expr",
        '(builtins.compareVersions "2.4" builtins.nixVersion) == 1',
    ]
    proc = subprocess.run(cmd, text=True, capture_output=True, check=True)
    return proc.stdout != "true"


class IntegrationTest(unittest.TestCase):
    def setUp(self) -> None:
        self.env = os.environ.copy()
        self.dir = TemporaryDirectory()
        self.env["HOME"] = str(self.dir.name)
        self.testenv = Path(self.dir.name).joinpath("testenv")
        shutil.copytree(TEST_ROOT.joinpath("testenv"), self.testenv)
        self.direnvrc = str(TEST_ROOT.parent.joinpath("direnvrc"))

    def test_nix_shell(self) -> None:
        with open(self.testenv.joinpath(".envrc"), "w") as f:
            f.write(f"source {self.direnvrc}\n" "use nix")

        run(["direnv", "allow"], cwd=str(self.testenv), env=self.env, check=True)

        run(["nix-collect-garbage"], check=True)

        out1 = run(
            ["direnv", "exec", str(self.testenv), "hello"],
            env=self.env,
            stderr=subprocess.PIPE,
            text=True,
        )
        sys.stderr.write(out1.stderr)
        self.assertIn("renewed cache and derivation link", out1.stderr)
        self.assertEqual(out1.returncode, 0)

        run(["nix-collect-garbage"], check=True)

        out2 = run(
            ["direnv", "exec", str(self.testenv), "hello"],
            env=self.env,
            stderr=subprocess.PIPE,
            text=True,
        )
        sys.stderr.write(out2.stderr)
        self.assertIn("using cached derivation", out2.stderr)
        self.assertEqual(out2.returncode, 0)

    @unittest.skipUnless(support_flakes(), "requires flakes")
    def test_nix_flake(self) -> None:
        with open(self.testenv.joinpath(".envrc"), "w") as f:
            f.write(f"source {self.direnvrc}\n" "use flake")

        run(["direnv", "allow"], cwd=str(self.testenv), env=self.env, check=True)

        run(["nix-collect-garbage"], check=True)

        out1 = run(
            ["direnv", "exec", str(self.testenv), "hello"],
            env=self.env,
            stderr=subprocess.PIPE,
            text=True,
        )
        sys.stderr.write(out1.stderr)
        self.assertIn("renewed cache", out1.stderr)
        self.assertEqual(out1.returncode, 0)

        run(["nix-collect-garbage"], check=True)

        out2 = run(
            ["direnv", "exec", str(self.testenv), "hello"],
            env=self.env,
            stderr=subprocess.PIPE,
            text=True,
        )
        sys.stderr.write(out2.stderr)
        self.assertIn("using cached dev shell", out2.stderr)
        self.assertEqual(out2.returncode, 0)

    def tearDown(self) -> None:
        self.dir.cleanup()


if __name__ == "__main__":
    unittest.main()
