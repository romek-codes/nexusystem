from __future__ import annotations

from functools import lru_cache
import hashlib
import json
import os
import re
import subprocess
import time
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any


CVE_CACHE_TTL_SECONDS = 60 * 60 * 24
DEFAULT_SORT = "severity"
CVE_RE = re.compile(r"(CVE-\d{4}-\d+|GHSA-[0-9A-Za-z-]+)")


class PackageAuditError(RuntimeError):
    pass


@dataclass
class PackageRecord:
    source: str
    name: str
    pname: str
    version: str
    out_path: str
    drv_path: str

    @property
    def display_name(self) -> str:
        return self.pname or self.name or self.basename

    @property
    def basename(self) -> str:
        candidate = self.out_path or self.drv_path or self.name
        value = candidate.rsplit("/", 1)[-1]
        if value.endswith(".drv"):
            value = value[:-4]
        if "-" in value:
            value = value.split("-", 1)[-1]
        return value


@dataclass
class VulnerabilityRecord:
    package: str
    cve: str
    severity: float | None
    description: str
    drv_path: str
    raw: dict[str, Any]


@dataclass
class PackageReportRow:
    package: PackageRecord
    vulnerabilities: list[VulnerabilityRecord]

    @property
    def cve_count(self) -> int:
        return len(self.vulnerabilities)

    @property
    def max_severity(self) -> float:
        scores = [entry.severity for entry in self.vulnerabilities if entry.severity is not None]
        return max(scores, default=0.0)

    def to_dict(self) -> dict[str, Any]:
        return {
            "source": self.package.source,
            "name": self.package.name,
            "pname": self.package.pname,
            "version": self.package.version,
            "outPath": self.package.out_path,
            "drvPath": self.package.drv_path,
            "cveCount": self.cve_count,
            "maxSeverity": self.max_severity,
            "vulnerabilities": [asdict(entry) for entry in self.vulnerabilities],
        }


def default_host() -> str:
    value = os.environ.get("PACKAGE_AUDIT_DEFAULT_HOST", "").strip()
    if not value:
        raise PackageAuditError("PACKAGE_AUDIT_DEFAULT_HOST is not set")
    return value


def flake_path() -> str:
    value = os.environ.get("PACKAGE_AUDIT_FLAKE_PATH", "").strip()
    if not value:
        raise PackageAuditError("PACKAGE_AUDIT_FLAKE_PATH is not set")
    return value


def cache_dir() -> Path:
    root = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
    path = root / "package-audit"
    path.mkdir(parents=True, exist_ok=True)
    return path


def _alias_cache_path(kind: str, host: str) -> Path:
    return cache_dir() / f"{kind}-latest-{host}.json"


def _run(command: list[str], check: bool = True) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(command, capture_output=True, text=True)
    if check and result.returncode != 0:
        message = result.stderr.strip() or result.stdout.strip() or "command failed"
        raise PackageAuditError(message)
    return result


def _nix_eval_json(expr: str) -> Any:
    result = _run(["nix", "eval", "--quiet", "--impure", "--json", "--expr", expr])
    payload = json.loads(result.stdout)
    if isinstance(payload, str):
        stripped = payload.strip()
        if stripped.startswith("[") or stripped.startswith("{"):
            try:
                return json.loads(stripped)
            except json.JSONDecodeError:
                return payload
    return payload


def _nix_eval_raw(expr: str) -> str:
    result = _run(["nix", "eval", "--quiet", "--impure", "--raw", "--expr", expr])
    return result.stdout.strip()


def _vulnix_version() -> str:
    result = _run(["vulnix", "--version"])
    return result.stdout.strip() or "unknown"


def _cache_key(*parts: str) -> str:
    digest = hashlib.sha256()
    for part in parts:
        digest.update(part.encode())
        digest.update(b"\0")
    return digest.hexdigest()


def _read_cache(path: Path, *, ttl: int | None = None) -> Any | None:
    if not path.exists():
        return None
    if ttl is not None and time.time() - path.stat().st_mtime > ttl:
        return None
    try:
        return json.loads(path.read_text())
    except json.JSONDecodeError:
        return None


def _write_cache(path: Path, payload: Any) -> None:
    path.write_text(json.dumps(payload))


def _write_cache_with_alias(path: Path, alias_path: Path, payload: Any) -> None:
    serialized = json.dumps(payload)
    path.write_text(serialized)
    alias_path.write_text(serialized)


def _inventory_expr(host: str) -> str:
    return f"""
let
  flake = builtins.getFlake "{flake_path()}";
  system = builtins.getAttr "{host}" flake.outputs.nixosConfigurations;
  username = system.config.var.username;
  clean = value:
    if builtins.isString value then builtins.unsafeDiscardStringContext value
    else value;
  format = source: pkg: {{
    inherit source;
    name = clean (pkg.name or "");
    pname = clean (pkg.pname or "");
    version = clean (pkg.version or "");
    outPath = clean (pkg.outPath or "");
    drvPath = clean (pkg.drvPath or "");
  }};
  keyFor = pkg:
    if pkg.outPath != "" then pkg.outPath
    else if pkg.drvPath != "" then pkg.drvPath
    else "${{pkg.source}}:${{pkg.name}}:${{pkg.version}}";
  dedupe = packages:
    builtins.attrValues (
      builtins.listToAttrs (
        map (pkg: {{
          name = keyFor pkg;
          value = pkg;
        }}) packages
      )
    );
  homeConfig = builtins.getAttr username system.config.home-manager.users;
  allPackages =
    map (format "system") system.config.environment.systemPackages
    ++ map (format "home") homeConfig.home.packages;
in
  builtins.toJSON (dedupe allPackages)
"""


def _drv_expr(host: str) -> str:
    return f"""
let
  flake = builtins.getFlake "{flake_path()}";
  system = builtins.getAttr "{host}" flake.outputs.nixosConfigurations;
in
  system.config.system.build.toplevel.drvPath
"""


def _hosts_expr() -> str:
    return f"""
let
  flake = builtins.getFlake "{flake_path()}";
in
  builtins.attrNames flake.outputs.nixosConfigurations
"""


def list_hosts() -> list[str]:
    return list(_nix_eval_json(_hosts_expr()))


@lru_cache(maxsize=32)
def resolve_drv_path(host: str) -> str:
    return _nix_eval_raw(_drv_expr(host))


def load_inventory(host: str, *, refresh: bool = False) -> list[PackageRecord]:
    drv_path = resolve_drv_path(host)
    cache_path = cache_dir() / f"inventory-{_cache_key(host, drv_path)}.json"
    alias_path = _alias_cache_path("inventory", host)

    if not refresh:
        cached = _read_cache(cache_path)
        if cached is not None:
            return [PackageRecord(**item) for item in cached]

    payload = _nix_eval_json(_inventory_expr(host))
    inventory = [_package_record_from_item(item) for item in payload]
    serialized = [asdict(item) for item in inventory]
    _write_cache_with_alias(cache_path, alias_path, serialized)
    return inventory


def load_vulnerabilities(host: str, *, refresh: bool = False) -> list[VulnerabilityRecord]:
    drv_path = resolve_drv_path(host)
    version = _vulnix_version()
    cache_path = cache_dir() / f"cves-{_cache_key(host, drv_path, version)}.json"
    alias_path = _alias_cache_path("cves", host)

    if not refresh:
        cached = _read_cache(cache_path, ttl=CVE_CACHE_TTL_SECONDS)
        if cached is not None:
            return [VulnerabilityRecord(**item) for item in cached]

    result = _run(["vulnix", "--json", drv_path], check=False)
    raw_output = result.stdout.strip() or "[]"
    try:
        payload = json.loads(raw_output)
    except json.JSONDecodeError as exc:
        raise PackageAuditError(f"failed to parse vulnix output: {exc}") from exc

    vulnerabilities = _normalize_vulnix(payload)
    serialized = [asdict(item) for item in vulnerabilities]
    _write_cache_with_alias(cache_path, alias_path, serialized)
    return vulnerabilities


def build_report(host: str, *, refresh: bool = False) -> list[PackageReportRow]:
    inventory = load_inventory(host, refresh=refresh)
    vulnerabilities = load_vulnerabilities(host, refresh=refresh)
    return merge_report(inventory, vulnerabilities)


def merge_report(inventory: list[PackageRecord], vulnerabilities: list[VulnerabilityRecord]) -> list[PackageReportRow]:
    return _merge_report(inventory, vulnerabilities)


def load_cached_report(host: str) -> list[PackageReportRow]:
    inventory_cached = _read_cache(_alias_cache_path("inventory", host))
    cves_cached = _read_cache(_alias_cache_path("cves", host), ttl=CVE_CACHE_TTL_SECONDS)
    if inventory_cached is None or cves_cached is None:
        return []
    inventory = [PackageRecord(**item) for item in inventory_cached]
    vulnerabilities = [VulnerabilityRecord(**item) for item in cves_cached]
    return merge_report(inventory, vulnerabilities)


def _merge_report(inventory: list[PackageRecord], vulnerabilities: list[VulnerabilityRecord]) -> list[PackageReportRow]:
    by_drv = {pkg.drv_path: pkg for pkg in inventory if pkg.drv_path}
    by_out = {pkg.out_path: pkg for pkg in inventory if pkg.out_path}
    by_name: dict[str, list[PackageRecord]] = {}
    for pkg in inventory:
        for key in {pkg.display_name, pkg.name, pkg.pname, pkg.basename}:
            if key:
                by_name.setdefault(key.lower(), []).append(pkg)

    matches: dict[str, list[VulnerabilityRecord]] = {pkg.drv_path or pkg.out_path or pkg.display_name: [] for pkg in inventory}

    for vulnerability in vulnerabilities:
        package: PackageRecord | None = None
        if vulnerability.drv_path:
            package = by_drv.get(vulnerability.drv_path) or by_out.get(vulnerability.drv_path)
        if package is None and vulnerability.package:
            candidates = by_name.get(vulnerability.package.lower(), [])
            if candidates:
                package = candidates[0]
        if package is None:
            continue
        key = package.drv_path or package.out_path or package.display_name
        matches.setdefault(key, []).append(vulnerability)

    rows = [
        PackageReportRow(
            package=pkg,
            vulnerabilities=sorted(
                matches.get(pkg.drv_path or pkg.out_path or pkg.display_name, []),
                key=lambda entry: (entry.severity or 0.0, entry.cve),
                reverse=True,
            ),
        )
        for pkg in inventory
    ]
    return rows


def sort_rows(rows: list[PackageReportRow], mode: str) -> list[PackageReportRow]:
    if mode == "name":
        return sorted(rows, key=lambda row: row.package.display_name.lower())
    if mode == "count":
        return sorted(rows, key=lambda row: (row.cve_count, row.max_severity, row.package.display_name.lower()), reverse=True)
    return sorted(rows, key=lambda row: (row.max_severity, row.cve_count, row.package.display_name.lower()), reverse=True)


def inventory_payload(host: str, *, refresh: bool = False) -> dict[str, Any]:
    packages = load_inventory(host, refresh=refresh)
    return {
        "host": host,
        "packageCount": len(packages),
        "packages": [
            {
                "source": pkg.source,
                "name": pkg.name,
                "pname": pkg.pname,
                "version": pkg.version,
                "outPath": pkg.out_path,
                "drvPath": pkg.drv_path,
            }
            for pkg in packages
        ],
    }


def cves_payload(host: str, *, refresh: bool = False) -> dict[str, Any]:
    vulnerabilities = load_vulnerabilities(host, refresh=refresh)
    return {
        "host": host,
        "vulnerabilities": [asdict(item) for item in vulnerabilities],
    }


def report_payload(host: str, *, refresh: bool = False) -> dict[str, Any]:
    rows = build_report(host, refresh=refresh)
    return {
        "host": host,
        "packageCount": len(rows),
        "packages": [row.to_dict() for row in rows],
    }


def _normalize_vulnix(payload: Any) -> list[VulnerabilityRecord]:
    findings: list[VulnerabilityRecord] = []

    if isinstance(payload, list) and payload and all(isinstance(item, dict) and "affected_by" in item for item in payload):
        for item in payload:
            package = item.get("pname") or item.get("name") or ""
            drv_path = item.get("derivation", "") or item.get("drvPath", "")
            scores = item.get("cvssv3_basescore", {}) if isinstance(item.get("cvssv3_basescore"), dict) else {}
            descriptions = item.get("description", {}) if isinstance(item.get("description"), dict) else {}
            for cve in item.get("affected_by", []):
                if not isinstance(cve, str):
                    continue
                score = scores.get(cve)
                if isinstance(score, str):
                    try:
                        score = float(score)
                    except ValueError:
                        score = None
                elif isinstance(score, (int, float)):
                    score = float(score)
                else:
                    score = None
                description = descriptions.get(cve, "")
                findings.append(
                    VulnerabilityRecord(
                        package=package,
                        cve=cve,
                        severity=score,
                        description=description if isinstance(description, str) else "",
                        drv_path=drv_path if isinstance(drv_path, str) else "",
                        raw=item,
                    )
                )
        return findings

    def visit(node: Any, context_package: str = "", context_drv: str = "") -> None:
        if isinstance(node, list):
            for item in node:
                visit(item, context_package, context_drv)
            return

        if not isinstance(node, dict):
            return

        drv = _first_string(node, ["drvPath", "drv_path", "derivation", "drv", "package_drv_path"]) or context_drv
        package = _package_name(node) or context_package

        vulnerability_list = None
        for key in ("vulnerabilities", "cves", "advisories"):
            if isinstance(node.get(key), list):
                vulnerability_list = node[key]
                break

        if vulnerability_list is not None:
            next_package = package or _package_name(node)
            next_drv = drv
            for item in vulnerability_list:
                findings.append(_to_vulnerability(item, next_package, next_drv))
            for key, value in node.items():
                if key not in {"vulnerabilities", "cves", "advisories"}:
                    visit(value, next_package, next_drv)
            return

        if _looks_like_vulnerability(node):
            findings.append(_to_vulnerability(node, package, drv))

        for key, value in node.items():
            next_drv = drv
            next_package = package
            if isinstance(key, str) and key.startswith("/nix/store/"):
                next_drv = key
                next_package = next_package or _basename_from_store_path(key)
            elif isinstance(key, str) and not next_package and key not in {"cvssv3_basescore", "cvss", "description"}:
                next_package = key
            visit(value, next_package, next_drv)

    visit(payload)

    deduped: dict[tuple[str, str, str], VulnerabilityRecord] = {}
    for finding in findings:
        key = (finding.package, finding.drv_path, finding.cve)
        current = deduped.get(key)
        if current is None or (finding.severity or 0.0) > (current.severity or 0.0):
            deduped[key] = finding
    return list(deduped.values())


def _package_name(node: dict[str, Any]) -> str:
    for key in ("package", "pname", "name"):
        value = node.get(key)
        if isinstance(value, str) and value and not CVE_RE.fullmatch(value):
            return value
        if isinstance(value, dict):
            nested = _package_name(value)
            if nested:
                return nested
    return ""


def _looks_like_vulnerability(node: dict[str, Any]) -> bool:
    if any(key in node for key in ("cvssv3_basescore", "cvss", "severity", "description")):
        return bool(_extract_cve(node))
    return bool(_extract_cve(node))


def _extract_cve(node: dict[str, Any]) -> str:
    for key in ("cve", "cveId", "id", "name", "title"):
        value = node.get(key)
        if isinstance(value, str):
            match = CVE_RE.search(value)
            if match:
                return match.group(1)
    return ""


def _extract_score(node: dict[str, Any]) -> float | None:
    for key in ("cvssv3_basescore", "cvss", "score", "severityScore"):
        value = node.get(key)
        if isinstance(value, (int, float)):
            return float(value)
        if isinstance(value, str):
            try:
                return float(value)
            except ValueError:
                continue
    nested = node.get("cvssv3") or node.get("cvssV3")
    if isinstance(nested, dict):
        return _extract_score(nested)
    return None


def _first_string(node: dict[str, Any], keys: list[str]) -> str:
    for key in keys:
        value = node.get(key)
        if isinstance(value, str) and value:
            return value
    return ""


def _basename_from_store_path(value: str) -> str:
    name = value.rsplit("/", 1)[-1]
    if name.endswith(".drv"):
        name = name[:-4]
    if "-" in name:
        name = name.split("-", 1)[-1]
    return name


def _split_name_version(value: str) -> tuple[str, str]:
    match = re.match(r"^(?P<name>.+)-(?P<version>\d[^/]*)$", value)
    if match:
        return match.group("name"), match.group("version")
    return value, ""


def _package_record_from_item(item: Any) -> PackageRecord:
    if isinstance(item, dict):
        return PackageRecord(
            source=item.get("source", ""),
            name=item.get("name", ""),
            pname=item.get("pname", ""),
            version=item.get("version", ""),
            out_path=item.get("outPath", ""),
            drv_path=item.get("drvPath", ""),
        )

    if isinstance(item, str):
        basename = _basename_from_store_path(item)
        pname, version = _split_name_version(basename)
        out_path = item if item.startswith("/nix/store/") and not item.endswith(".drv") else ""
        drv_path = item if item.endswith(".drv") else ""
        return PackageRecord(
            source="unknown",
            name=basename,
            pname=pname,
            version=version,
            out_path=out_path,
            drv_path=drv_path,
        )

    raise PackageAuditError(f"unexpected inventory item type: {type(item).__name__}")


def _to_vulnerability(node: Any, package: str, drv_path: str) -> VulnerabilityRecord:
    if not isinstance(node, dict):
        raw = {"value": node}
        cve = CVE_RE.search(str(node))
        return VulnerabilityRecord(
            package=package,
            cve=cve.group(1) if cve else str(node),
            severity=None,
            description="",
            drv_path=drv_path,
            raw=raw,
        )

    description = ""
    for key in ("description", "summary", "details"):
        value = node.get(key)
        if isinstance(value, str):
            description = value
            break
    resolved_package = package or _package_name(node) or (_basename_from_store_path(drv_path) if drv_path else "")
    return VulnerabilityRecord(
        package=resolved_package,
        cve=_extract_cve(node) or "unknown",
        severity=_extract_score(node),
        description=description,
        drv_path=drv_path or _first_string(node, ["drvPath", "drv_path", "derivation", "drv"]),
        raw=node,
    )
