#!/usr/bin/env bash
set -euo pipefail

# Deploiement OrnithoQuizz vers Alwaysdata.
# Par defaut : essai a blanc. Rien n'est transfere sans --go.
#   ./scripts/deploy.sh              essai
#   ./scripts/deploy.sh --go         transfert reel
#   ./scripts/deploy.sh --delete     essai, en signalant les fichiers excedentaires du serveur
#   ./scripts/deploy.sh --go --delete  transfert reel + suppression des excedentaires

DEST="vince63@ssh-vince63.alwaysdata.net:/home/vince63/www/"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/"

MODE=(--dry-run)
DELETE=()

for arg in "$@"; do
  case "$arg" in
    --go)     MODE=() ;;
    --delete) DELETE=(--delete) ;;
    *) echo "Option inconnue : $arg" >&2; exit 1 ;;
  esac
done

BRANCHE_DEPLOIEMENT="main"
BRANCHE=$(git -C "$SRC" branch --show-current)

if [ ${#MODE[@]} -eq 0 ]; then
  if [ "$BRANCHE" != "$BRANCHE_DEPLOIEMENT" ]; then
    echo "Refus : branche courante '$BRANCHE', deploiement attendu depuis '$BRANCHE_DEPLOIEMENT'." >&2
    exit 1
  fi
  if [ -n "$(git -C "$SRC" status --porcelain)" ]; then
    echo "Refus : arbre de travail non propre. Committe, remise ou nettoie avant de deployer." >&2
    exit 1
  fi
else
  echo "[essai] branche courante : $BRANCHE"
fi

rsync -rltzvi "${MODE[@]}" "${DELETE[@]}" \
  --chmod=D755,F644 \
  --exclude='/.env' \
  --exclude='/.git/' \
  --exclude='/.gitattributes' \
  --exclude='/.gitignore' \
  --exclude='/.vscode/' \
  --exclude='/Dockerfile' \
  --exclude='/README.md' \
  --exclude='/apache.conf' \
  --exclude='/conception/' \
  --exclude='/docker-compose.yml' \
  --exclude='/php-error-logging.ini' \
  --exclude='/scripts/' \
  --exclude='/storage/' \
  --exclude='/public/birdnet-model/' \
  "$SRC" "$DEST"
