#!/usr/bin/env bash
set -uo pipefail

echo "==> 1. Validation statique des workflows (actionlint)..."
if command -v actionlint &>/dev/null; then
    if ! actionlint; then
        echo "❌ Erreurs de syntaxe détectées dans les workflows" >&2
        exit 1
    fi
    echo "✓ Syntaxe valide."
else
    echo "❌ 'actionlint' n'est pas installé. Installez-le pour valider la syntaxe." >&2
    exit 1
fi

echo "==> 2. Audit de sécurité des workflows (Scorecard)..."
if command -v scorecard &>/dev/null; then
    # Checks locaux rapides sans blocage réseau
    scorecard --local . --checks Dangerous-Workflow,Token-Permissions \
        || echo "⚠️ Remarques de sécurité détectées ci-dessus." >&2
else
    echo "ℹ️ 'scorecard' non installé, étape ignorée."
fi

echo "==> 3. Test d'exécution locale (act)..."
if command -v act &>/dev/null; then
    if ! act -n; then
        echo "❌ Erreurs de simulation locale avec act" >&2
        exit 1
    fi
    echo "✓ Simulation act réussie."
else
    echo "ℹ️ 'act' n'est pas installé sur cette machine (optionnel). Étape ignorée."
fi

echo "✅ Validation des workflows terminée."