import 'package:flutter/material.dart';

/// Board layout (11 nodes):
///
///  [0]────[1]────[2]        ← Blue home (top horizontal)
///          |
///         [3]               ← top-circle  (vertical enters circle from top)
///        / | \
///      [4]─[5]─[6]          ← left-circle, center hub, right-circle
///        \ | /
///         [7]               ← bottom-circle (vertical exits circle below)
///          |
///  [8]────[9]────[10]       ← Red home (bottom horizontal)
///
/// Circle passes through nodes 3 (top), 4 (left), 7 (bottom), 6 (right).
/// Node 5 is the center of the circle — intersection of vertical + horizontal.
/// Lines drawn: top-row (0-2), vertical (1→3→5→7→9), horizontal in circle (4-5-6),
///              circle arc (3-4-7-6-3), bottom-row (8-10).

// ── Board geometry fractions ──────────────────────────────────────
const double kCircleR = 0.22; // circle radius as fraction of board width
const double kPieceR  = 0.06; // piece  radius as fraction of board width
const double kHitR    = 0.10; // tap hit-test radius fraction

// ── Node positions (fractions of board width/height) ─────────────
const List<Offset> kNodePos = [
  Offset(0.20, 0.05), // 0   top-left   (Blue home)
  Offset(0.50, 0.05), // 1   top-center (Blue home) — vertical origin
  Offset(0.80, 0.05), // 2   top-right  (Blue home)
  Offset(0.50, 0.28), // 3   top-circle   = (0.5, 0.5 − kCircleR)
  Offset(0.28, 0.50), // 4   left-circle  = (0.5 − kCircleR, 0.5)
  Offset(0.50, 0.50), // 5   center hub
  Offset(0.72, 0.50), // 6   right-circle = (0.5 + kCircleR, 0.5)
  Offset(0.50, 0.72), // 7   bottom-circle = (0.5, 0.5 + kCircleR)
  Offset(0.20, 0.95), // 8   bottom-left  (Red home)
  Offset(0.50, 0.95), // 9   bottom-center (Red home) — vertical terminus
  Offset(0.80, 0.95), // 10  bottom-right (Red home)
];

// ── Adjacency (lines + circle arc) ───────────────────────────────
const List<List<int>> kAdj = [
  [1],           // 0   top-left   → top row only
  [0, 2, 3],     // 1   top-center → top row + vertical down to circle
  [1],           // 2   top-right  → top row only
  [1, 5, 4, 6],  // 3   top-circle → vertical (to 1, to 5) + arc (to 4, to 6)
  [5, 3, 7],     // 4   left-circle  → horizontal (to 5) + arc (to 3, to 7)
  [3, 7, 4, 6],  // 5   center hub → vertical (3↔7) + horizontal (4↔6)
  [5, 3, 7],     // 6   right-circle → horizontal (to 5) + arc (to 3, to 7)
  [5, 9, 4, 6],  // 7   bottom-circle → vertical (to 5, to 9) + arc (to 4, to 6)
  [9],           // 8   bottom-left  → bottom row only
  [8, 10, 7],    // 9   bottom-center → bottom row + vertical up to circle
  [9],           // 10  bottom-right → bottom row only
];

// ── Starting positions ────────────────────────────────────────────
const List<int> kBlueStart = [0, 1, 2]; // Blue occupies the top row
const List<int> kRedStart  = [8, 9, 10]; // Red  occupies the bottom row

// ── Home zones (for win detection) ───────────────────────────────
const List<int> kBlueHome = [0, 1, 2]; // Blue's territory (Red must invade here)
const List<int> kRedHome  = [8, 9, 10]; // Red's territory (Blue must invade here)

// Pieces needed in opponent's home to win
const int kWinCount = 3; // all pieces must reach opponent's home
