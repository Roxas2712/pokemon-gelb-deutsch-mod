# Herkunft der deutschen Texte – Gelbe Edition

Die Mod wird lokal mit `tools/build_official_german_mod.py` aus einer
unveränderten deutschen ROM von **Pokémon Gelbe Edition – Special Pikachu
Edition** erzeugt.

Aus der ROM stammen:

- Dialoge und Pokédex-Texte
- Pokémon-, Attacken-, Item-, Trainer- und Typnamen
- Pokédex-Kategorien
- der vollständige deutsche Font
- die Titelgrafik „GELBE EDITION“

Engine-Texte werden, soweit möglich, über ihre englischen ROM-Texte den
offiziellen deutschen Fassungen zugeordnet. Nur Gen1Recomp-Zusatzfunktionen
ohne Game-Boy-Gegenstück stehen als geprüfte Übersetzungen im Buildskript.

Die ROM wird ausschließlich gelesen und weder in die Mod noch in das
Mod-Archiv kopiert.

## Lokaler Neuaufbau

Benötigt werden die deutsche ROM mit SHA-1
`42f3714eec6eca25200d42461ff08d57c98f6d1d`, die passende US-ROM mit
SHA-1 `cc7d03262ebfaf2f06772c1a480c7d9d5f4a38e1` und die Symboldateien der
bytegenau passenden deutschen und englischen Disassembly-Builds.

```sh
python3 tools/build_official_german_mod.py \
  --version yellow \
  --rom "/Pfad/Pokemon - Gelbe Edition (Germany).gb" \
  --symbols "/Pfad/pokeyellow-de/pokeyellow.sym" \
  --english-rom "/Pfad/Pokemon - Yellow Version (USA, Europe).gbc" \
  --english-symbols "/Pfad/pokeyellow/pokeyellow.sym"
```

Danach:

```sh
MODKIT_LUAJIT="$PWD/.tools/luajit-src/src/luajit" \
  python3 tools/modkit.py validate deutsch-gelb --base imported --strict
python3 tools/modkit.py lint deutsch-gelb
```
