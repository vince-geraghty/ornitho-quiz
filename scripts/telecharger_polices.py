"""
Rapatrie les polices Google utilisées par le site et génère leur feuille de style.

Prérequis — récupérer le CSS de Google avec un User-Agent moderne
(sans quoi Google renvoie du .ttf au lieu du .woff2) :

  curl -s -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36" \
    "https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,700;1,400&family=DM+Sans:wght@300;400;500&display=swap" \
    > /tmp/gfonts.css

Usage, depuis la racine du projet :
  python3 scripts/telecharger_polices.py        # affiche les curl + écrit fonts.css
  python3 scripts/telecharger_polices.py | sh   # idem, et exécute les téléchargements
"""

import re
import pathlib

CSS_SOURCE    = '/tmp/gfonts.css'
DOSSIER_FONTS = 'public/assets/fonts'      # où atterrissent les .woff2
CHEMIN_WEB    = '/assets/fonts'            # comment le navigateur les demande
CSS_SORTIE    = 'public/assets/css/fonts.css'
GARDES        = {'latin', 'latin-ext'}     # sous-ensembles conservés

css = pathlib.Path(CSS_SOURCE).read_text()
blocs = re.findall(r'/\*\s*([\w-]+)\s*\*/\s*@font-face\s*\{(.*?)\}', css, re.S)

fontes = {}   # url -> métadonnées ; une police variable revient plusieurs fois
ordre  = []   # pour garder l'ordre d'apparition

for sous_ensemble, corps in blocs:
    if sous_ensemble not in GARDES:
        continue

    url     = re.search(r'src:\s*url\(([^)]+)\)', corps).group(1)
    famille = re.search(r"font-family:\s*'([^']+)'", corps).group(1)
    style   = re.search(r'font-style:\s*(\w+)', corps).group(1)
    graisse = int(re.search(r'font-weight:\s*(\d+)', corps).group(1))
    plage   = re.search(r'unicode-range:\s*([^;]+);', corps).group(1).strip()

    if url not in fontes:
        slug   = famille.lower().replace(' ', '-')
        italic = '-italic' if style == 'italic' else ''
        fontes[url] = {
            'famille':  famille,
            'style':    style,
            'plage':    plage,
            'graisses': set(),
            'nom':      f'{slug}{italic}-{sous_ensemble}.woff2',
        }
        ordre.append(url)

    fontes[url]['graisses'].add(graisse)

# 1. les commandes de téléchargement, sur la sortie standard
for url in ordre:
    print(f'curl -o {DOSSIER_FONTS}/{fontes[url]["nom"]} "{url}"')

# 2. la feuille de style, écrite directement
lignes = [
    '/* Généré par scripts/telecharger_polices.py — ne pas éditer à la main. */',
    '',
]
for url in ordre:
    f = fontes[url]
    g = sorted(f['graisses'])
    # une seule graisse -> valeur simple ; plusieurs -> plage (police variable)
    poids = str(g[0]) if len(g) == 1 else f'{g[0]} {g[-1]}'
    lignes += [
        '@font-face {',
        f"    font-family: '{f['famille']}';",
        f"    font-style: {f['style']};",
        f"    font-weight: {poids};",
        '    font-display: swap;',
        f"    src: url('{CHEMIN_WEB}/{f['nom']}') format('woff2');",
        f"    unicode-range: {f['plage']};",
        '}',
        '',
    ]

pathlib.Path(CSS_SORTIE).write_text('\n'.join(lignes))