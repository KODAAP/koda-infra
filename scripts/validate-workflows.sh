#!/usr/bin/env bash
set -uo pipefail

echo "Validation statique avec actionlint..."
if ! actionlint; then
    echo "Erreurs de syntaxe detectees" >&2
    exit 1
fi

echo "Audit securite avec Scorecard..."
scorecard --local . --checks Token-Permissions,Pinned-Dependencies,Dangerous-Workflow \
    || echo "Problemes de securite detectes (voir ci-dessus)" >&2

echo "Test d'execution a blanc avec act..."
if ! act -n; then
    echo "Erreurs d'execution detectees" >&2
    exit 1
fi

echo "Workflows valides."