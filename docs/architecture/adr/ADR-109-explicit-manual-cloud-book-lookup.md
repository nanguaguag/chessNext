# ADR-109: Explicit manual cloud-book lookup

- Status: accepted
- Date: 2026-11-05
- Scope: F15, B10; M4-78

## Context

The project already has a self-hosted read-only book query endpoint, a bounded
HTTP adapter, and a query path used by the analysis single-move action. The main
workspace had no way to browse a book manually. A visitor could not inspect
operator-supplied candidates without asking the AI action to choose and play a
move.

## Decision

Add a main-workspace cloud-book panel with explicit opening/endgame selection
and a user-triggered query button. With no configured endpoint it is offline
and sends nothing. A query sends only the current FEN, selected book kind, and
the current line's move history to the configured `BookService` endpoint.
Candidates are rechecked against the current legal move set and displayed with
operator-supplied dataset/license/attribution metadata. This panel never plays
a move. Changing the game-tree cursor or book kind invalidates an outstanding
response and clears the previous candidates. Network, HTTP rejection, malformed
data, and a valid miss have distinct user-facing states.

The service call is owned by `BookLookupController`; the widget only renders
state and sends an explicit query intent. No user identity, device telemetry,
or record metadata is transmitted. The app sends no request on startup or when
the current position changes.

## Consequences and limits

- The panel is a manual read-only F15 slice; the site's exact `云库/大师谱`
  selector semantics, master-game filters, response ranking and server data
  remain unverified.
- Opening/endgame choice is explicit. Automatic classification is not inferred
  from the source site; the separate AI single-move policy retains its project
  classification proposal.
- Real deployment, data licenses, and operator service configuration remain
  deployment requirements. Without a configured endpoint the feature remains
  offline.
