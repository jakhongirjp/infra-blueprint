#!/usr/bin/env python3
"""Policy checks on rendered Kubernetes manifests.

Usage: helm template ... | scripts/check_chart_policy.py

Fails (exit 1) if any workload breaks the platform's baseline: non-root,
read-only root filesystem, no privilege escalation, dropped capabilities,
pinned image, resource requests and probes. This is the same baseline the
cluster enforces with Pod Security Admission "restricted", caught earlier.
"""
import sys

import yaml

WORKLOADS = {"Deployment", "StatefulSet", "DaemonSet", "Job", "CronJob"}


def pod_spec(doc):
    spec = doc["spec"]
    if doc["kind"] == "CronJob":
        spec = spec["jobTemplate"]["spec"]
    return spec["template"]["spec"]


def check(doc):
    name = f'{doc["kind"]}/{doc["metadata"]["name"]}'
    spec = pod_spec(doc)
    problems = []
    pod_sc = spec.get("securityContext", {})
    if not pod_sc.get("runAsNonRoot"):
        problems.append("pod must set runAsNonRoot: true")
    if pod_sc.get("seccompProfile", {}).get("type") != "RuntimeDefault":
        problems.append("pod must use the RuntimeDefault seccomp profile")
    if spec.get("automountServiceAccountToken", True):
        problems.append("service account token must not be auto-mounted")
    for c in spec.get("containers", []):
        sc = c.get("securityContext", {})
        where = f'container "{c["name"]}"'
        if sc.get("allowPrivilegeEscalation", True):
            problems.append(f"{where}: allowPrivilegeEscalation must be false")
        if not sc.get("readOnlyRootFilesystem"):
            problems.append(f"{where}: readOnlyRootFilesystem must be true")
        if "ALL" not in sc.get("capabilities", {}).get("drop", []):
            problems.append(f"{where}: must drop ALL capabilities")
        image = c.get("image", "")
        if image.endswith(":latest") or ("@" not in image and ":" not in image.rsplit("/", 1)[-1]):
            problems.append(f"{where}: image {image!r} must be pinned to a tag or digest")
        if not c.get("resources", {}).get("requests"):
            problems.append(f"{where}: resource requests are required")
        if doc["kind"] in {"Deployment", "StatefulSet"} and not c.get("readinessProbe"):
            problems.append(f"{where}: readinessProbe is required")
    return [f"{name}: {p}" for p in problems]


def main():
    docs = [d for d in yaml.safe_load_all(sys.stdin) if d]
    workloads = [d for d in docs if d.get("kind") in WORKLOADS]
    if not workloads:
        print("no workloads found in input", file=sys.stderr)
        return 1
    problems = [p for d in workloads for p in check(d)]
    for p in problems:
        print(f"FAIL {p}")
    print(f"checked {len(workloads)} workload(s), {len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
