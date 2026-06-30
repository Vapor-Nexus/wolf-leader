"""Arc5K — Architecture Optimizer integration for Wolf Leader.

Wolf Leader stays orchestration + storage only: it builds the kickoff prompt that
points an AI assistant at the Arc5K skill, and files the finished review back into
the project's memory. The assistant (in Cursor/Claude) does the actual read-only
reviewing and runs the tools Arc5K relies on.
"""
import os
from datetime import date
from typing import Any, Dict, List, Optional

from . import hub
from .branding import PRODUCT_NAME

# Review layers Arc5K understands. "holistic" reviews everything (the default).
ARC5K_LAYERS = ("holistic", "db", "etl", "backend", "api", "frontend")

# Memory type used when filing a review report back into the project.
ARC5K_MEMORY_TYPE = "note"


def _public_url() -> str:
    return os.environ.get("IDE_STORAGE_PUBLIC_URL", "http://127.0.0.1:6971").rstrip("/")


def _mcp_url() -> str:
    return os.environ.get("IDE_STORAGE_MCP_URL", "http://127.0.0.1:6972/mcp")


def normalize_layers(layers: Optional[List[str]]) -> List[str]:
    """Keep only known layers; default to holistic when nothing valid is given."""
    if not layers:
        return ["holistic"]
    cleaned = [l.strip().lower() for l in layers if l and l.strip()]
    valid = [l for l in cleaned if l in ARC5K_LAYERS]
    return valid or ["holistic"]


def report_subdir(today: Optional[str] = None) -> str:
    """Where the review output lands inside the reviewed repo."""
    return f"docs/arch-review/{today or date.today().isoformat()}"


def build_arc5k_prompt(
    project: Dict[str, Any], layers: Optional[List[str]] = None
) -> Dict[str, Any]:
    """Build the ready-to-run kickoff prompt for a project.

    Returns the prompt text plus metadata the UI/agent can use. Does not touch the
    database — this only assembles instructions.
    """
    layers = normalize_layers(layers)
    name = project.get("name") or project.get("slug") or "this project"
    slug = project.get("slug") or str(project.get("id") or "")
    repo_path = project.get("compose_path") or project.get("path") or "<the project repo>"
    out_dir = report_subdir()
    layer_phrase = (
        "every layer (database, ETL, backend, API, and Vue frontend)"
        if "holistic" in layers
        else "the " + ", ".join(layers) + " layer(s)"
    )

    prompt = (
        f"Run an Arc5K architecture review of {name}.\n\n"
        f"Use the `arc5k` skill. Review {layer_phrase}, strictly read-only — never "
        f"change code and never write to any database, and only ever run against "
        f"local/dev (never production).\n\n"
        f"Project repo: {repo_path}\n\n"
        f"Steps:\n"
        f"1. Follow the arc5k skill: gather facts with its read-only scripts and the "
        f"tools it lists, walk the per-layer prompts, decide where each calculation "
        f"should live, and rank findings worst-first.\n"
        f"2. Write the report, fix plan, and DB-target guide into `{out_dir}/` in the "
        f"project repo, in dead-simple plain English.\n"
        f"3. File the review back into {PRODUCT_NAME}: call the `arc5k_review` MCP tool "
        f"with slug=\"{slug}\" and report=<the full report markdown> so it's saved to "
        f"this project's memory. (If MCP isn't available, POST the report to "
        f"{_public_url()}/api/projects/{slug}/arc5k/report instead.)"
    )

    return {
        "ok": True,
        "project_id": project.get("id"),
        "slug": slug,
        "name": name,
        "layers": layers,
        "repo_path": repo_path,
        "report_dir": out_dir,
        "prompt": prompt,
        "mcp_url": _mcp_url(),
        "report_url": f"{_public_url()}/api/projects/{slug}/arc5k/report",
    }


def store_arc5k_report(
    project_id: int,
    report: str,
    layers: Optional[List[str]] = None,
    source_chat_id: Optional[int] = None,
) -> Dict[str, Any]:
    """File a finished Arc5K review into the project's memory."""
    if not report or not report.strip():
        raise ValueError("report is empty")
    layers = normalize_layers(layers)
    today = date.today().isoformat()
    scope = "all layers" if "holistic" in layers else ", ".join(layers)
    header = f"Arc5K architecture review ({today}, {scope})"
    content = f"{header}\n\n{report.strip()}"
    result = hub.remember(
        project_id,
        ARC5K_MEMORY_TYPE,
        content,
        source_chat_id=source_chat_id,
        semantic_descriptor="Arc5K architecture review findings and fix plan",
    )
    return {"ok": True, "stored": header, **result}
