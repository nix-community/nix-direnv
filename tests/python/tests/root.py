from pathlib import Path

import pytest

TEST_ROOT = Path(__file__).parent.resolve()
PROJECT_ROOT = TEST_ROOT.parents[2]


@pytest.fixture
def test_root() -> Path:
    """
    Root directory of the tests
    """
    return TEST_ROOT


@pytest.fixture
def project_root() -> Path:
    """
    Root directory of the project
    """
    return PROJECT_ROOT
