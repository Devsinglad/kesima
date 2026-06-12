#!/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Circle & Cross — Shisima Game
#  Setup script: scaffolds Flutter boilerplate, then runs the app.
# ─────────────────────────────────────────────────────────────────

set -e
cd "$(dirname "$0")"

echo ""
echo "════════════════════════════════════════"
echo "  Circle & Cross — Shisima Game Setup   "
echo "════════════════════════════════════════"
echo ""

# ── 1. Check Flutter is installed ────────────────────────────────
if ! command -v flutter &> /dev/null; then
  echo "❌  Flutter not found."
  echo ""
  echo "    Install it from: https://docs.flutter.dev/get-started/install"
  echo "    Then re-run this script."
  exit 1
fi

echo "✅  Flutter found: $(flutter --version | head -1)"
echo ""

# ── 2. Scaffold missing boilerplate if needed ────────────────────
#    flutter create fills in android/, ios/, web/, test/ etc.
#    --project-name sets the app ID; --org sets the package namespace.
if [ ! -d "android" ]; then
  echo "📦  Generating Flutter project scaffold..."
  flutter create . \
    --project-name circle_cross_game \
    --org com.example \
    --description "Shisima — Traditional Kenyan Strategy Game" \
    --platforms android,ios
  echo ""
fi

# ── 3. Pull dependencies ─────────────────────────────────────────
echo "📥  Getting dependencies..."
flutter pub get
echo ""

# ── 4. List available devices ────────────────────────────────────
echo "📱  Available devices:"
flutter devices
echo ""

# ── 5. Run ───────────────────────────────────────────────────────
echo "🚀  Launching app..."
echo "    (Press 'r' to hot-reload, 'R' to restart, 'q' to quit)"
echo ""
flutter run
