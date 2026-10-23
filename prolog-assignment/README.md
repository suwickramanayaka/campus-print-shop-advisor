# Campus Print Shop Advisor

A Sri Lankan campus printing-shop assignment built entirely in SWI-Prolog. It asks follow-up questions, finds suitable printing options, explains rejections, manages stock and orders, and checks completion deadlines. Prices are illustrative, not real shop quotations.

## Run on this Mac

Use **`/opt/homebrew/bin/swipl` — SWI-Prolog 10.0.2, arm64-darwin**. The initial `which -a swipl` and `swipl --version` checks found no executable, and neither common Homebrew location nor `/Applications` contained SWI-Prolog. Homebrew was installed, so SWI-Prolog was installed there. This explicit path avoids ambiguity with a future DMG installation. Homebrew reported certificate/OpenSSL post-install warnings; the installed Prolog executable, tests and local HTTP server worked successfully.

In Terminal:

```sh
cd "/Users/sithumuthsara/On My Mac Documents/Development/Assigment  - Logic Programming and Deductive Reasoning/prolog-assignment"
/opt/homebrew/bin/swipl -q -s main.pl
```

At the Prolog prompt:

```prolog
start.
```

Everyday menu answers **do not need a full stop**. Enter `0` to leave the main menu, then `halt.` to leave Prolog. Alternatively, double-click `run_console.command` in Finder.

For the web interface, in the same Prolog process:

```prolog
start_web.
```

Open <http://localhost:8080>. Keep Prolog running. `stop_web.` stops the server. You may run `start.` after `start_web.` so both interfaces share the same live database. Alternatively, double-click `run_web.command`.

**Run only one application process at a time.** Database operations are protected between threads within one process; the flat-file database does not coordinate separate processes. Run automated tests after stopping the demo process, or use their isolated test database as provided.

## What to enter

- Pages per copy: integer 1–1000; copies: integer 1–100.
- Colour required: `yes` allows only colour; `no` allows both, cheapest first.
- Double-sided acceptable: `yes` allows single and double; `no` allows only single.
- Binding required: `no` skips the binding question; `yes` asks `staple`, `spiral` or `either`.
- Budget: whole LKR, 0–10,000,000.
- Deadline: `YYYY-MM-DD HH:MM` in Sri Lanka time, or `none`. Enter a real date at or after the displayed shop clock.
- Stock materials: `paper`, `staple`, `spiral`. Add a positive quantity, set a nonnegative quantity, or remove the record. A removed material is unavailable until added again.

Sample: `40`, `3`, `no`, `yes`, `yes`, `spiral`, `1020`, `none` produces one available option with initial stock: double-sided black-and-white with spiral binding, LKR 1,020. Choose `1`, then `yes` to confirm. Paper falls from 80 to 20, spiral units from 10 to 7.

## Pricing and assumptions

| Charge | LKR |
|---|---:|
| Black-and-white per printed side | 5 |
| Colour per printed side | 20 |
| A4 sheet | 2 |
| Staple set per copy | 5 |
| Spiral binding unit per copy | 100 |

Paper is charged separately from printing. Double-sided printing saves paper, not printed sides. Each copy starts on a fresh sheet: five pages × three copies double-sided needs nine sheets. Stapling supports up to 20 physical sheets per copy; spiral binding supports up to 200. These are sample limits. One staple stock unit means one complete stapling set for one copy.

All pages use the selected print mode. Quotes do not reserve stock. Confirmation checks current stock again. Cancellation returns reserved materials only up to the scheduled start minute. After that minute, cancellation is rejected to avoid returning materials assumed to be in use. Cancelling permanently removes that order record; it is not a historical accounting ledger. No tax, mixed-colour pages, ink inventory, file uploads, payments or printer connection is included.

## Deadline checking

The sample shop has **one FIFO production station**, open **09:00–17:00 every day**, including weekends. All displayed times are Sri Lanka time (UTC+05:30), independent of the computer timezone. These are demonstration assumptions, not measured machine performance.

| Production assumption | Value |
|---|---:|
| Setup per order | 2 minutes |
| BW printing | 20 printed sides/minute |
| Colour printing | 10 printed sides/minute |
| Stapling | 1 minute/copy |
| Spiral binding | 3 minutes/copy |

Printing time rounds up to whole minutes. A 40-page, three-copy BW spiral order takes `2 + ceil(120/20) + 3×3 = 17` working minutes. Double-sided printing saves sheets but uses the same printing-time estimate in this simple model.

The next order starts after the latest reserved finish, or at the current shop time if the queue has elapsed. Work pauses at 17:00 and resumes at 09:00 the next day. For example, a 17-minute job beginning at 16:50 finishes at 09:07 the following day. Finishing exactly at the requested deadline is accepted.

A quotation shows estimated start and finish times without reserving a slot. Confirmation rechecks the deadline and saves a `booking(OrderId,Start,Finish,Deadline)` fact together with the order and stock changes. A changed queue can invalidate an earlier quotation. A rejected deadline leaves stock and orders untouched and shows the earliest completion among options that meet requirements, budget and stock.

Bookings preserve existing promised times. Cancelling a queued order removes its booking but does not move other bookings earlier or fill internal gaps. When the final queued order is cancelled, the tail becomes available again. The model assumes work progresses as scheduled; it does not track printer failures, operator delays or actual completion events.

Existing saved orders from the earlier version remain compatible. On loading an old order without a booking, the system assigns a new estimated slot with no deadline. These migrated slots persist on the next successful save.

For a repeatable classroom demonstration, before starting the interfaces use:

```prolog
set_demo_time('2026-10-23 09:00').
```

This freezes the clock and the interface explicitly labels it **Frozen demo clock**. Use it only with disposable demonstration data. `use_live_time.` returns to the real clock; restarting also restores live time. The live clock rounds up to the next whole minute. See the updated demo guide for exact inputs.

## Files and line budget

The core is **256 physical lines including comments**, across `main.pl`, `knowledge_base.pl`, `engine.pl`, `records.pl` and `scheduling.pl`. The two interfaces, tests and verification helpers are separate from the core, as agreed.

| File | Purpose |
|---|---|
| `main.pl` | Entry loader and initialization |
| `knowledge_base.pl` | Rates, materials, limits, questions, validation |
| `engine.pl` | Answers, candidate generation, pricing, suitability, explanations |
| `records.pl` | Dynamic stock/orders, transactions, persistence, aggregations |
| `scheduling.pl` | Production duration, FIFO queue, working hours and deadlines |
| `ui_console.pl` | Menu loops and input handling |
| `ui_web.pl` | Local HTTP pages, session isolation and forms |
| `data/db.pl` | Current stock, orders, reserved schedules and next order number |
| `tests.pl` | 47 plunit tests |
| `DEMO_GUIDE.md` | Walkthrough, concept map and viva preparation |
| `sample_runs.txt` | Actual captured console sessions with input lists |
| `verification/` | Reproducible checks and results |

## Tests

```sh
/opt/homebrew/bin/swipl -g run_tests -t halt tests.pl
python3 verification/capture_console.py
```

The tests and console capture use temporary databases; they do not modify `data/db.pl`. Unit checks cover calculations, binding limits, mandatory requirements, session answers, invalid values, confirmation/cancellation, stale quotes, persistence, aggregation rollback on save failure, exact deadlines, queue delays, closed hours, multi-day work and saved schedules.

`verification/check_web.py` is an optional HTTP integration check for a **disposable demo server** at port 8081 with a frozen `2026-10-23 09:00` demo clock. It modifies sample stock, creates and cancels an order, and advances the order counter; do not run it against data you want to keep. Results are in `verification/web_results.txt`. Browser interaction was also checked separately.

## Persistence and a fresh demonstration

Changes save automatically. The application writes a temporary snapshot, then renames it over `data/db.pl`. In-memory changes roll back if saving fails. Files are read as validated data terms, never executed as directives. Keep this application local: there is no login or production access-control system. The server binds only to `127.0.0.1`; sessions separate consultation answers, not stock-management privileges.

To reset your own disposable demonstration data, stop other running instances, back up `data/db.pl` if needed, then use:

```prolog
reset_records, save_db.
```

This clears orders and restores 80 sheets, 30 staple sets and 10 spiral units. Restarting normally preserves your saved data. Do not edit the data file while the server is running. A malformed hand-edited database may fail to load; restore a backup rather than treating it as source code.

## Troubleshooting

- `swipl: command not found`: use `/opt/homebrew/bin/swipl`. Check `which -a swipl` and `/opt/homebrew/bin/swipl --version`.
- Prolog waits after `start`: type the full stop: `start.`. Within menus, enter plain values without a full stop.
- The dedicated membership demo uses `read/1`: enter `paper.` and press Enter. It is the only menu feature requiring Prolog-term syntax.
- Port 8080 busy: stop the existing demo with `stop_web.` or exit its Terminal process. Do not start a second instance.
- After editing code: use `make.` at the Prolog prompt. To reload changed startup state reliably, restart after saving data.
- Browser shows a stale-question or unavailable-option message: start a new consultation. Browser tabs in the same browser profile share a session; separate browsers have separate consultations.

The four-slide presentation is in `presentation/`. It summarizes the problem, shared Prolog logic, deadline example and concepts.
