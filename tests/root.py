from pathlib import Path

import pytest

TEST_ROOT = Path(__file__).parent.resolve()
PROJECT_ROOT = TEST_ROOT.parent


@pytest.fixture()
def test_root() -> Path:
    """
    Root directory of the tests
    """
    return TEST_ROOT


@pytest.fixture()
def project_root() -> Path:
    """
    Root directory of the tests
    """
    return PROJECT_ROOT
