# ADR-110: Operator supplied master-game index query

- Status: accepted
- Date: 2026-11-05
- Scope: F15, F20; M4-80 server slice

## Context

E86 observed master-game filters for category, player/event text, years, and
result. E87 observed the visible text placeholder and number-input DOM
declarations (`min=1`, `max=9999`) but did not change or submit any filter.
The reference site's position matching, text matching, result semantics,
ordering, paging, returned record shape, and actual year boundaries remain
unknown. No licensed third-party game corpus is available in the project.

## Decision

Add an optional self-hosted, read-only `POST /v1/master-games/query` endpoint
backed by operator supplied `master-games.json`. Each indexed record contains a
unique ID, exact FEN and complete history key, category (`game` or
`chessbook`), red/black players, event, year, and result. Queries can filter by
category, case-insensitive substring over player/event, inclusive year range,
and a set of results; pagination is bounded to 50 records. Dataset
license/attribution accompanies metadata responses. Results preserve manifest
order. No full game record is returned in this slice.

The endpoint is disabled unless `CHESSNEXT_MASTER_GAMES_ROOT` is configured.
The server includes no sample corpus. Operators must replace the empty template
with data they own or are authorized to index and display. Queries are bounded,
not logged or persisted by the service, and rate limited in the sample Nginx
configuration.

## Consequences and limits

- This establishes a replaceable backend contract and deployment path; it does
  not complete the Flutter query UI or game retrieval/player playback.
- Exact FEN plus full history, substring search, inclusive range, manifest
  order, and page size are project proposals, not inferred source-site behavior.
- The browser's `1..9999` DOM attributes are observation only; actual keyboard,
  stepper, and committed boundaries remain U.
- Dataset authorization remains the operator's responsibility. No site data,
  copied game records, or game corpus ships with the repository.
