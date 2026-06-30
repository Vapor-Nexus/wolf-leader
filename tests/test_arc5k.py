"""Tests for the Arc5K architecture-review integration."""
from __future__ import annotations

import json

from ide_storage import arc5k
from ide_storage.db import db_conn


def _make_project(*, name="Demo App", slug="demo-app", compose_path="/srv/demo") -> int:
    with db_conn() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO projects (name, path, slug, status, created_at, updated_at, compose_path)
            VALUES (?, ?, ?, 'active', ?, ?, ?)
            """,
            (name, "/tmp/p", slug, "now", "now", compose_path),
        )
        conn.commit()
        return int(cur.lastrowid)


# --- normalize_layers ---------------------------------------------------------

def test_normalize_layers_defaults_to_holistic():
    assert arc5k.normalize_layers(None) == ["holistic"]
    assert arc5k.normalize_layers([]) == ["holistic"]
    assert arc5k.normalize_layers(["nonsense"]) == ["holistic"]


def test_normalize_layers_keeps_known_layers():
    assert arc5k.normalize_layers(["DB", "frontend", "bogus"]) == ["db", "frontend"]


# --- build_arc5k_prompt -------------------------------------------------------

def test_build_arc5k_prompt_holistic_mentions_read_only_and_skill():
    project = {"id": 7, "slug": "demo-app", "name": "Demo App", "compose_path": "/srv/demo"}
    out = arc5k.build_arc5k_prompt(project)
    assert out["ok"] is True
    assert out["layers"] == ["holistic"]
    assert out["report_dir"].startswith("docs/arch-review/")
    prompt = out["prompt"]
    assert "arc5k" in prompt              # tells the agent which skill to use
    assert "read-only" in prompt          # the non-negotiable safety rule
    assert "/srv/demo" in prompt          # points at the project repo
    assert "arc5k_review" in prompt       # how to file the report back


def test_build_arc5k_prompt_specific_layers():
    project = {"id": 1, "slug": "x", "name": "X"}
    out = arc5k.build_arc5k_prompt(project, layers=["db", "api"])
    assert out["layers"] == ["db", "api"]
    assert "db, api" in out["prompt"]


# --- store_arc5k_report -------------------------------------------------------

def test_store_arc5k_report_files_a_memory():
    pid = _make_project()
    report = "# Architecture Review\n\nThe seed-cost formula lives in 3 places."
    result = arc5k.store_arc5k_report(pid, report, layers=["holistic"])
    assert result["ok"] is True

    with db_conn() as conn:
        cur = conn.cursor()
        cur.execute(
            "SELECT type, content, semantic_descriptor FROM memories WHERE project_id = ?",
            (pid,),
        )
        rows = cur.fetchall()
    assert len(rows) == 1
    row = rows[0]
    assert row["type"] == arc5k.ARC5K_MEMORY_TYPE
    assert "Arc5K architecture review" in row["content"]
    assert "seed-cost formula" in row["content"]
    assert "Arc5K" in (row["semantic_descriptor"] or "")


def test_store_arc5k_report_rejects_empty():
    pid = _make_project(slug="empty-demo")
    try:
        arc5k.store_arc5k_report(pid, "   ")
        assert False, "expected ValueError for empty report"
    except ValueError:
        pass
