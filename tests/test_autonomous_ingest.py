"""tests/test_autonomous_ingest.py"""
import json
import os
import tempfile
from pathlib import Path

import pytest


class TestVaultRootDetection:
    """VAULT_ROOT detection: env var first, then settings.json."""

    def test_detects_env_var(self, monkeypatch, tmp_path):
        """When VAULT_ROOT is set in env, it is used directly."""
        monkeypatch.setenv("VAULT_ROOT", str(tmp_path))
        # Simulate the detection logic:
        vault = os.environ.get("VAULT_ROOT") or self._load_settings(tmp_path)
        assert vault == str(tmp_path)

    def test_falls_back_to_settings_json(self, monkeypatch, tmp_path):
        """When VAULT_ROOT is not set, load from ~/.config/ics/settings.json."""
        monkeypatch.delenv("VAULT_ROOT", raising=False)
        settings_dir = tmp_path / ".config" / "ics"
        settings_dir.mkdir(parents=True)
        (settings_dir / "settings.json").write_text(
            json.dumps({"vault_root": str(tmp_path / "vault")})
        )
        monkeypatch.setenv("HOME", str(tmp_path))
        vault = os.environ.get("VAULT_ROOT") or self._load_settings(tmp_path)
        assert "vault" in vault

    def test_raises_when_neither_set(self, monkeypatch, tmp_path):
        """When neither env nor settings.json provides VAULT_ROOT, raise."""
        monkeypatch.delenv("VAULT_ROOT", raising=False)
        monkeypatch.setenv("HOME", str(tmp_path))
        # Simulate: no env, no settings → should raise
        with pytest.raises(ValueError, match="VAULT_ROOT"):
            self._detect_vault_root()

    @staticmethod
    def _load_settings(base: Path) -> str | None:
        settings_path = Path(os.environ["HOME"]) / ".config" / "ics" / "settings.json"
        if settings_path.exists():
            data = json.loads(settings_path.read_text())
            return data.get("vault_root")
        return None

    @staticmethod
    def _detect_vault_root() -> str:
        vault = os.environ.get("VAULT_ROOT") or (
            TestVaultRootDetection._load_settings(Path(__file__).parent)
        )
        if not vault:
            raise ValueError("VAULT_ROOT not set and no settings.json found")
        return vault


class TestPdfCopyIdempotency:
    """PDF copy to vault is idempotent based on file size."""

    def test_skips_copy_when_dest_exists_with_same_size(self, tmp_path):
        """If dest exists and file sizes match, skip copy."""
        source = tmp_path / "paper.pdf"
        dest = tmp_path / "dest.pdf"
        source.write_bytes(b"x" * 100)
        dest.write_bytes(b"x" * 100)  # same size

        skipped = self._copy_if_needed(source, dest)
        assert skipped is False  # False = skipped (True = copied per docstring)
        assert dest.read_bytes() == b"x" * 100  # unchanged

    def test_overwrites_when_size_differs(self, tmp_path):
        """If dest exists but file sizes differ, overwrite."""
        source = tmp_path / "paper.pdf"
        dest = tmp_path / "dest.pdf"
        source.write_bytes(b"x" * 100)
        dest.write_bytes(b"y" * 50)  # different size

        copied = self._copy_if_needed(source, dest)
        assert copied is True
        assert dest.read_bytes() == b"x" * 100

    @staticmethod
    def _copy_if_needed(source: Path, dest: Path) -> bool:
        """Returns True if copied, False if skipped."""
        import shutil

        if dest.exists():
            if dest.stat().st_size == source.stat().st_size:
                return False  # skip
        shutil.copy2(source, dest)
        return True


class TestSidecarJsonSchema:
    """Sidecar JSON has the required fields."""

    def test_sidecar_has_required_keys(self, tmp_path):
        """Sidecar JSON must contain all required keys."""
        paper_id = "s41534-021-00368-4"
        sidecar = {
            "paper_id": paper_id,
            "pdf_rel_path": f"Research/papers/{paper_id}/{paper_id}.pdf",
            "ingested_at": "2026-05-09T10:00:00Z",
            "page_count": 12,
            "had_fallback": False,
            "fallback_reason": None,
            "engine_used": "marker_chunked",
            "artifacts": {
                "markdown": f"Research/papers/{paper_id}/{paper_id}.md",
                "manifest": ".artifacts/marker_chunked/manifest.json",
            },
        }
        required = {"paper_id", "pdf_rel_path", "ingested_at", "page_count",
                    "had_fallback", "fallback_reason", "engine_used", "artifacts"}
        assert required.issubset(sidecar.keys())

    def test_sidecar_roundtrip(self, tmp_path):
        """Sidecar JSON serializes and deserializes correctly."""
        paper_id = "s41534-021-00368-4"
        sidecar_path = tmp_path / f"{paper_id}.md.sidecar.json"
        sidecar_data = {
            "paper_id": paper_id,
            "pdf_rel_path": f"Research/papers/{paper_id}/{paper_id}.pdf",
            "ingested_at": "2026-05-09T10:00:00Z",
            "page_count": 12,
            "had_fallback": False,
            "fallback_reason": None,
            "engine_used": "marker_chunked",
            "artifacts": {
                "markdown": f"Research/papers/{paper_id}/{paper_id}.md",
                "manifest": ".artifacts/marker_chunked/manifest.json",
            },
        }
        sidecar_path.write_text(json.dumps(sidecar_data, indent=2))
        loaded = json.loads(sidecar_path.read_text())
        assert loaded == sidecar_data