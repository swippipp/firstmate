#!/usr/bin/env bash
# fm-gauntlet-strukturvergleich.sh - B5f independence probe comparator.
#
# Two gauntlet runs over IDENTICAL args must show an identical verdict
# STRUCTURE incl. the Belegpfad field (AP1 acceptance) - never word-identical
# texts, since LLM output is not even batch-invariant across otherwise-equal
# calls. Structural, therefore, means exactly the letter of AP1:
#
#   FATAL if:
#     - the two runs do not each carry six Urteils-Slots,
#     - the linse names differ (slot by slot),
#     - a Urteil misses one of its mandatory fields
#       (linse / urteil / befunde / fixes),
#     - value-level types break (urteil outside the scale, befunde entries
#       without art/text, fixes entries no longer plain text),
#     - the primary-source lens (vollstaendigkeit-existenz ...) lacks a
#       non-empty belegpfad in either run.
#
#   Informational only (never fatal): how many findings or fixes each lens
#   produced, optional extra fields such as quelle on individual findings or
#   belegpfad on non-primary lenses, round depth, discard counters, Synthese
#   prose. Sharpening onto those would make the probe rotate unstably - the
#   exact trap the Aussenwelt lens warns about (batch nondeterminism).
#
# Usage:
#   fm-gauntlet-strukturvergleich.sh <lauf-a.json> <lauf-b.json>
set -eu

SELF="$0"

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  sed -n '2,36{s/^# \{0,1\}//;p;}' "$SELF"
  exit 0
fi

[ "$#" -eq 2 ] || {
  printf 'fm-gauntlet-strukturvergleich.sh: genau zwei Lauf-Dateien erwartet.\n' >&2
  exit 2
}
for datei in "$1" "$2"; do
  [ -f "$datei" ] || {
    printf 'fm-gauntlet-strukturvergleich.sh: Lauf-Datei fehlt: %s\n' "$datei" >&2
    exit 2
  }
done

command -v python3 >/dev/null 2>&1 || {
  printf 'fm-gauntlet-strukturvergleich.sh: python3 wird gebraucht.\n' >&2
  exit 1
}

python3 - "$1" "$2" <<'PY'
import json, sys

SKALA = {"reif", "reif-mit-vermerken", "nicht-reif"}
PFLICHTFELDER = ["linse", "urteil", "befunde", "fixes"]
PRIMAERQUELLEN_MUSTER = "vollstaendigkeit-existenz"


def lade(pfad):
    roh = json.load(open(pfad, encoding="utf-8"))
    if isinstance(roh, dict) and isinstance(roh.get("result"), dict):
        roh = roh["result"]
    return roh


def verletzungen(name, lauf):
    """Prueft einen Einzellauf gegen die Struktur; Liste von Mangel-Zeilen."""
    mangel = []
    if not isinstance(lauf, dict) or not isinstance(lauf.get("urteile"), list):
        return [f"{name}: kein Gauntlet-Ergebnis mit urteile[]"]
    urteile = lauf["urteile"]
    if len(urteile) != 6:
        mangel.append(
            f"{name}: {len(urteile)} Urteils-Slots statt sechs "
            "(5 Innen + Aussenwelt)"
        )
    for i, u in enumerate(urteile):
        ort = f"{name} slot {i}"
        if not isinstance(u, dict):
            mangel.append(f"{ort}: Urteil ist kein Objekt")
            continue
        fehlend = [f for f in PFLICHTFELDER if f not in u]
        if fehlend:
            mangel.append(f"{ort}: Pflichtfelder fehlen: {', '.join(fehlend)}")
        if "urteil" in u and u["urteil"] not in SKALA:
            mangel.append(f"{ort}: urteil ausserhalb der Skala: {u['urteil']!r}")
        if "fixes" in u and (
            not isinstance(u["fixes"], list)
            or not all(isinstance(x, str) for x in u["fixes"])
        ):
            mangel.append(f"{ort}: fixes ist keine Textliste")
        if "befunde" not in u or not isinstance(u["befunde"], list):
            mangel.append(f"{ort}: befunde ist keine Liste")
            continue
        for j, b in enumerate(u["befunde"]):
            if not isinstance(b, dict):
                mangel.append(f"{ort} befunde[{j}]: kein Objekt")
                continue
            ohne = [
                f
                for f in ("art", "text")
                if not isinstance(b.get(f), str) or not b[f]
            ]
            if ohne:
                mangel.append(
                    f"{ort} befunde[{j}]: art/text fehlt oder leer: "
                    f"{', '.join(ohne)}"
                )
    return mangel


a, b = lade(sys.argv[1]), lade(sys.argv[2])
rot = 0

for name, lauf in (("A", a), ("B", b)):
    for zeile in verletzungen(name, lauf):
        print(f"FATAL {zeile}")
        rot += 1

ua = a.get("urteile") or [] if isinstance(a, dict) else []
ub = b.get("urteile") or [] if isinstance(b, dict) else []
print(f"Laeufe: A={len(ua)} Urteile, B={len(ub)} Urteile")

for i, (x, y) in enumerate(zip(ua, ub)):
    lx = x.get("linse") if isinstance(x, dict) else None
    ly = y.get("linse") if isinstance(y, dict) else None
    if lx != ly:
        print(f"FATAL slot {i}: Linse-Namen weichen ab: {lx!r} vs {ly!r}")
        rot += 1
    # Belegpfad-Pflicht (AP1): fuer die primaerquellen-lesende Linse an beiden
    # Vorhaben - vorhanden UND nichtleerer Text, nicht bloss Feldexistenz.
    if isinstance(lx, str) and PRIMAERQUELLEN_MUSTER in lx:
        for seit, u in (("A", x), ("B", y)):
            bp = u.get("belegpfad") if isinstance(u, dict) else None
            if not (isinstance(bp, str) and bp.strip()):
                print(
                    f"FATAL slot {i} ({lx}) Lauf {seit}: "
                    "belegpfad der Primaerquellen-Linse fehlt oder ist leer"
                )
                rot += 1
    else:
        zaehler = "A=%s/B=%s" % tuple(
            len(u.get("befunde", [])) if isinstance(u, dict) else "?"
            for u in (x, y)
        )
        print(f"slot {i} ({lx}): Befundzahl Laufvarianz nur informativ ({zaehler})")

for schluessel in (
    "maxRunden", "rundenGelaufen", "verworfeneQuellenloseBefunde",
    "aussenweltZusatz",
):
    if isinstance(a, dict) and isinstance(b, dict):
        print(
            f"Informativ (nicht entscheidend) {schluessel}: "
            f"A={json.dumps(a.get(schluessel))[:60]} "
            f"B={json.dumps(b.get(schluessel))[:60]}"
        )

if rot:
    sys.exit(f"Strukturvergleich ROT ({rot} Befund[e])")
print(
    "Strukturvergleich GRUEN: sechs Urteils-Slots mit gleichen Linsen,"
    " Pflichtfeldern, Skalenwerten und Belegpfad-Pflicht stimmen ueberein"
)
PY
