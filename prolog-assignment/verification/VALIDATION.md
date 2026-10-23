# Validation — 23 October 2026

Runtime: SWI-Prolog 10.0.2 for arm64-darwin. Core: 256 physical lines across main, knowledge base, engine, records and scheduling. Interfaces and tests are separate.

- All 47 plunit tests passed without load warnings. Includes 21 new scheduling checks: duration, date validation, local time conversion, before/after opening, exact closing/deadline, multi-day carry, queue delays, failed-deadline atomicity, persistence, cancellation and legacy migration.
- All 20 HTTP assertions passed against an isolated server at port 8081 with a frozen 2026-10-23 09:00 clock. They cover the existing flows plus invalid deadlines, earliest completion explanations, timing display, saved bookings and shared queue delays.
- Ten console sessions replayed with isolated databases and a frozen demo clock. Real input/output is in ../sample_runs.txt.
- Browser walkthrough verified a 09:16 deadline rejection with earliest finish 09:17, then an accepted 09:17 quotation for the 17-minute sample job. Screenshot: deadline-preview.png.
- The application server on port 8080 uses live Sri Lanka time and the existing database. The tests used a separate file and did not change data/db.pl.
- Listener check confirmed 127.0.0.1:8080, rather than all network interfaces.

Scheduling assumptions: one FIFO station, daily 09:00–17:00 hours, setup 2 minutes, BW 20 sides/minute, colour 10 sides/minute, staple 1 minute/copy and spiral 3 minutes/copy. Rates are illustrative. The clock rounds up to a whole minute. Already-booked times remain fixed after cancellation, and internal gaps are not reused. The model assumes work proceeds as scheduled and does not monitor real equipment. Cancellation after the scheduled start minute is rejected. Existing orders without bookings receive estimated slots on load.
