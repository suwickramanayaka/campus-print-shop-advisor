# Campus Print Shop Advisor — Demo Guide

## Two-minute opening (English)

My project is a rule-based advisor for a small printing shop near a Sri Lankan university. A customer may know the page count and budget but may not know which printing and binding choices are practical. The shop also needs to check whether enough paper and binding materials are available.

The system asks follow-up questions and stores the answers for the current consultation. It considers colour requirements, whether double-sided printing is acceptable, and whether binding is needed. It skips the binding-type question when the customer does not need binding.

Prolog generates configurations from facts and rules. Each configuration is priced and checked against binding capacity, the customer's budget available stock and the requested completion deadline. Feasible configurations are displayed cheapest first. If none qualifies, the system explains the blocking category. It never changes an essential requirement just to produce a cheap answer.

A quotation does not change stock. Confirmation checks stock again, records the order and deducts materials. Cancelling before work has progressed beyond the scheduled start minute returns those materials. Changes are saved to a local data file.

The console and browser interfaces call the same core logic. The project demonstrates facts, rules, unification, backtracking, recursion, list processing, aggregation, dynamic database updates, cuts, negation and input/output in one practical system. It is a small educational model with sample prices, rather than a production printing or payment application.

## ඒක casual Sinhala වලින් තේරුම් ගන්න

“මේක campus එක ළඟ printing shop එකකට උදව් කරන system එකක්. Customerගෙන් පිටු ගණන, copies, colour අවශ්‍යද, binding ඕනද, budget එක කීයද වගේ දේවල් අහනවා. ඒ උත්තර facts විදිහට තියාගෙන rules අනුව options හොයනවා.

ගාන අඩුම එක කියලා විතරක් යෝජනා කරන්නේ නෑ. Customerට ඒක ගැළපෙන්නත් ඕන, stock එකේ බඩු තියෙන්නත් ඕන. Confirm කළාම විතරයි stock අඩු වෙන්නේ. Console එකෙන් හෝ browser එකෙන් කළත් වැඩ කරන්නේ එකම Prolog logic එක.”

## Before the lecturer arrives

1. Use the Homebrew executable `/opt/homebrew/bin/swipl`.
2. Open Terminal in `prolog-assignment`, run `/opt/homebrew/bin/swipl -q -s main.pl`.
3. For a fresh **disposable** demo, use `reset_records, save_db, set_demo_time('2026-10-23 09:00').` This clears orders and freezes the clock for repeatable results. The interface labels the frozen clock.
4. Run `start_web.` then `start.` in the same process. Open `http://localhost:8080` in a browser. Do not launch a second application process.
5. Have `engine.pl`, `records.pl`, this guide and `verification/test_results.txt` open.
6. Main menus take values without a full stop. The Prolog prompt and dedicated term demo require a full stop.

## 8–10 minute demonstration

Allow roughly two minutes for the opening above, then follow these steps with the frozen demo clock. Values below are entered one per line. Menu labels identify when to type them.

| Time | Action and exact inputs | What to point out |
|---|---|---|
| 2:00–2:30 | Main menu: `2`, then `6`, `1`, `0` | Initial stock 80/30/10. Empty aggregation behavior. The clock is explicitly frozen at 09:00. |
| 2:30–3:15 | `1`, `abc`, `40`, `3`, `no`, `yes`, `yes`, `spiral`, `1000`, `none` | Rejects invalid page input. Budget is insufficient even without a deadline. |
| 3:15–4:00 | `1`, `40`, `3`, `no`, `yes`, `yes`, `spiral`, `1020`, `2026-10-23 09:16` | Budget and stock fit, but the 17-minute job misses 09:16. Earliest completion is 09:17. |
| 4:00–5:00 | `1`, `40`, `3`, `no`, `yes`, `yes`, `spiral`, `1020`, `2026-10-23 09:17`, `1`, `yes` | Exact deadline is accepted. Order 1 finishes 09:17. Printing takes 6 minutes, setup 2, binding 9. Price stays LKR 1,020. |
| 5:00–5:30 | `2`, `4`, then `3`, `1`, `paper`, `60`, `0` | Inspect order schedule and stock. Replenish 60 sheets to support the next order. |
| 5:30–6:15 | `1`, `40`, `3`, `no`, `yes`, `yes`, `spiral`, `1020`, `2026-10-23 09:20` | Existing booking delays the next job. Earliest completion is now 09:34. No stock deduction on rejection. |
| 6:15–7:00 | Repeat with deadline `2026-10-23 09:34`, then `1`, `yes`; choose `6`, `1` | Order 2 uses 09:17–09:34. `findall` repeats materials, `setof` removes duplicates, `bagof` groups IDs. |
| 7:00–7:30 | Reports: `2`, `paper.`, `0`; main menu: `5`, `2` | Demonstrate `read/1` and custom membership. Cancel queued order 2 and return its materials. |
| 7:30–8:30 | Browser: start new consultation, enter `5`, `1`, `no`, `yes`, `no`, `100`, `none` | Binding-type question is skipped. Both interfaces use the same scheduling logic. This small job begins after order 1. Leave it unconfirmed. |
| 8:30–9:30 | Show `work_finish/3`, `reserve/4`, concept map and test results | Recursion carries work across closed hours. Reservation rechecks the deadline inside the stock/order transaction. |

If a demo answer is mistyped, use Start a new consultation in the web UI. In the console, finish the quotation and choose `0` instead of confirming, or exit and restart. Invalid values are re-requested. A valid but unintended answer is not automatically corrected.

## Prolog for beginners

- **Fact:** `rate(bw,5).` means one black-and-white printed side costs five rupees in our sample model. සිංහලෙන්: අපි දන්න තොරතුරක්.
- **Rule:** `stock_ok([M-Q|Rest])` succeeds if the current item is available in sufficient quantity and the remaining items are also available. කොන්දේසි සම්පූර්ණ නම් නිගමනය ඇත්ත වෙනවා.
- **Unification:** `quote(T,bw,double,spiral,Items)` matches a quotation and binds `T` and `Items`. It is structural matching, not an assignment statement.
- **Backtracking:** `side_option(yes,Side)` can first produce `single`, then `double`. Prolog revisits alternatives when a later condition fails or another answer is requested.
- **Recursion:** `costs([],[])` is the base case. `costs([M-Q|Rest],[Cost|Costs])` processes one item and calls itself on the tail. List එකේ එක item එක කරලා ඉතුරු ටිකට ඒ වැඩේම කරනවා.
- **Cut:** `!` discards choice points created since entering the current predicate. It does not stop the whole application. `known/3` uses it after a unique answer is found; `reason/2` commits to one prioritised explanation.
- **Negation as failure:** `\+ quote(R,_)` succeeds when Prolog cannot find a quote for that request. It means failure to prove within our database, not universal real-world falsity. We use it after the request is known.
- **Dynamic database:** `stock(paper,80)` can be replaced with `stock(paper,20)` at runtime using `retract` and `assertz`. In-memory facts need explicit persistence to survive a restart.

## 15 likely viva questions

1. **Why Prolog for this project?** The main problem is expressing price, stock and deadline constraints and searching alternatives. Facts and rules make those decisions explicit; backtracking enumerates options.
2. **How is this different from a calculator?** It conditionally asks questions, excludes incompatible configurations, checks availability and explains why options fail; calculation is only one part.
3. **How are facts different from rules?** A fact records a relationship directly, such as a price. A rule derives a relationship when its body succeeds, such as stock sufficiency for a list of items.
4. **Where does backtracking occur?** In colour, side and binding choices inside `quote/2`. `findall/3` collects the alternatives that also satisfy stock and budget constraints.
5. **Why store answers dynamically?** Later questions and rules reuse them without asking again. Each answer includes a session ID. New consultations clear only their own answers.
6. **Why is `known/3` a green cut?** There is at most one answer per session/key because `put_answer/3` replaces the previous one. With those arguments bound, removing the cut does not change successful answers. This claim depends on that invariant and calling mode.
7. **Why is `reason/2` a red cut?** It intentionally gives only the first applicable reason. Without cuts, other clauses—including the fallback success message—could also succeed. Clause order defines priority.
8. **How do the three aggregation predicates differ?** `findall` retains duplicates and returns `[]` if there are no solutions. `bagof` retains duplicates, groups by free variables and fails when empty. `setof` groups similarly but sorts and removes duplicates, also failing when empty.
9. **What does `^` do in the aggregation rules?** It existentially quantifies variables so they do not create groups. In `orders_by_binding/2`, binding remains free and defines the groups.
10. **Why not use `read/1` for every menu input?** It expects Prolog terms and a terminating full stop. Line input is friendlier and validates numbers explicitly. A small separate membership demo demonstrates `read/1`.
11. **Where are lists and recursion meaningful?** Material requirements are lists of material–quantity pairs. Recursive predicates calculate cost, check stock, consume items and return them on cancellation.
12. **Why recheck stock when confirming?** Another consultation may have consumed materials since quotation. Confirmation rechecks inside a mutex and transaction before changing any records.
13. **What happens if saving fails?** The in-memory transaction rolls back. Saving writes a temporary file and renames it. This is a small local persistence model, not a fully crash-proof multi-process database.
14. **Does double-sided printing halve the print charge?** No. The number of printed sides is unchanged. Only physical sheets decrease, rounded up separately for every copy.
15. **What are the limitations and next extension?** Sample rates, A4 only, no mixed-colour pages, no actual production monitoring or real printer integration, and one application process. A future extension could track actual completion or multiple printers.

## Deadline enhancement explained casually

“දැන් system එක stock සහ budget බලන එකට අමතරව customerට ඕන වෙලාවට order එක ඉවර කරන්න පුළුවන්ද කියලත් බලනවා. පිටු 40ක copies තුනක් BW spiral කළොත් වැඩ කරන විනාඩි 17ක් ඕන. Shop එකේ වෙන වැඩ නැත්නම් 9ට පටන් අරන් 9:17ට ඉවරයි. කලින් එවැනි order එකක් තිබුණොත් දෙවෙනි එක ඉවර වෙන්නේ 9:34ට.

හවස 5ට shop එක වහන නිසා ඉතුරු වැඩ ඊළඟ දවසේ 9ට පටන් ගන්නවා. මේක actual printer එකක speed එකක් නෙවෙයි, demo assumptions අනුව හදපු estimate එකක්.”

Extra viva: **Why keep existing booked times after cancellation?** To avoid silently changing promised schedules. This conservative model only appends jobs to the queue tail and does not optimize internal gaps.

Extra viva: **Why store the booking?** Recomputing every old job from scratch on each request would make the queue move forward indefinitely. Stored start/finish times let elapsed work leave the active queue.

## Troubleshooting during the demo

| Symptom | Fix |
|---|---|
| Wrong Prolog executable | Use `/opt/homebrew/bin/swipl`; inspect `which -a swipl` and its `--version`. |
| Prompt waits after `start` | Add `.` at the Prolog prompt. Menus use plain answers. |
| Term demo waits after `paper` | Type `.` then Enter. |
| Port 8080 busy | Stop the already-running server/process; do not run two copies. |
| Code edits not visible | Use `make.` at the Prolog prompt; restart if startup data changed. |
| Unexpected stock/order IDs | A previous run was saved. For disposable demo data only, use `reset_records, save_db.` before starting. |
| Browser question differs from another tab | Same-browser tabs share a session. Use separate browsers for separate consultations. |
| Deadline says invalid | Use exact `YYYY-MM-DD HH:MM` format, Sri Lanka time, at or after the displayed clock; or enter `none`. |
| Cancellation rejected | The scheduled start minute has passed. Stock is no longer assumed unused. |
| Empty result | Explain the rejection; it is valid reasoning, not necessarily a program error. |

## Concept-to-code map

Line numbers below refer to the delivered source files. A line may identify the first clause of a multi-clause predicate.

| Concept | File | Predicate | Line | Explanation |
|---|---|---|---:|---|
| Facts and rules | [knowledge_base.pl](knowledge_base.pl#L3) | `rate/2; material/2` | 3 | Sample rates and materials form the knowledge base. |
| Head/tail recursion; custom list predicate | [engine.pl](engine.pl#L35) | `costs/2` | 35 | Recursively converts requirements into cost values. |
| append/3 | [engine.pl](engine.pl#L31) | `requirements/4` | 31 | Combines paper and binding requirements. |
| sum_list/2; is/2 | [engine.pl](engine.pl#L43) | `quote/2` | 43 | Totals material costs and printed-side costs. |
| sort/2 | [engine.pl](engine.pl#L52) | `quotes/2` | 52 | Sorts quotations by their first field, price, and removes duplicates. |
| nth1/3; length/2 | [engine.pl](engine.pl#L63) | `option/3` | 63 | Validates and selects a numbered quotation. |
| member/2 | [engine.pl](engine.pl#L9) | `next_question/2` | 9 | Searches the ordered question list. |
| Custom membership | [engine.pl](engine.pl#L39) | `my_member/2` | 39 | Recursive membership used by the term demo. |
| findall/3 | [records.pl](records.pl#L77) | `material_occurrences/1` | 77 | Retains repeated materials across orders; empty orders return []. |
| bagof/3 | [records.pl](records.pl#L71) | `orders_by_binding/2` | 71 | Groups order IDs by binding; fails when empty. |
| setof/3 | [records.pl](records.pl#L74) | `ordered_materials/1` | 74 | Produces sorted unique material names; fails when empty. |
| dynamic declarations | [records.pl](records.pl#L3) | `stock/2; order/3; next_id/1` | 3 | Allows records to change at runtime. |
| assertz/1; retractall/1 | [engine.pl](engine.pl#L6) | `put_answer/3` | 6 | Replaces one saved answer without creating duplicates. |
| retract/1 | [records.pl](records.pl#L49) | `consume/1` | 49 | Removes each old stock fact before asserting its replacement. |
| Session reset | [engine.pl](engine.pl#L3) | `new_session/1` | 3 | Clears answers for one consultation. |
| Green cut | [engine.pl](engine.pl#L5) | `known/3` | 5 | Commits to a unique answer for a bound session and question. |
| Red cut | [engine.pl](engine.pl#L57) | `reason/2` | 57 | Commits to the first applicable rejection category. |
| fail-driven loop | [ui_console.pl](ui_console.pl#L50) | `print_stock/0` | 50 | Prints each stock fact by deliberate backtracking, then succeeds. |
| Negation as failure | [engine.pl](engine.pl#L9) | `next_question/2; reason/2` | 9 | Finds unanswered questions and detects no provable candidate. |
| read/1 | [ui_console.pl](ui_console.pl#L77) | `term_demo/0` | 77 | Reads a material atom as a Prolog term. |
| write/1; nl/0 | [ui_console.pl](ui_console.pl#L3) | `main_menu/0` | 3 | Displays the boxed menu and line breaks. |
| format/2 | [ui_console.pl](ui_console.pl#L50) | `print_stock/0` | 50 | Aligns stock columns using tab stops. |
| between/3; validation | [knowledge_base.pl](knowledge_base.pl#L23) | `valid/2` | 23 | Checks integer ranges; rejects nonnumeric and fractional page counts. |
| Arithmetic comparison | [engine.pl](engine.pl#L41) | `stock_ok/1` | 41 | Requires each available quantity to meet its required quantity. |
| Conditional questioning | [engine.pl](engine.pl#L12) | `needed/2` | 12 | Asks binding type only when binding is required. |
| Persistence and rollback | [records.pl](records.pl#L35) | `mutate/1; save_db/0` | 35 | Serializes writes and rolls back in-memory updates on save failure. |
| Shared HTTP core | [ui_web.pl](ui_web.pl#L28) | `web_do/4` | 28 | Web confirmation calls the same confirm/3 as the console. |
| Deadline enhancement | [scheduling.pl](scheduling.pl#L28) | `work_finish` | 28 | Recursive working-time calculation across closed hours. |
| Deadline enhancement | [scheduling.pl](scheduling.pl#L42) | `session_quotes` | 42 | Filters quotes by the requested deadline. |
| Deadline enhancement | [scheduling.pl](scheduling.pl#L52) | `reserve` | 52 | Rechecks and stores the schedule during confirmation. |
| Deadline enhancement | [scheduling.pl](scheduling.pl#L54) | `booking_text` | 54 | Displays saved start, finish and deadline. |
| Deadline enhancement | [scheduling.pl](scheduling.pl#L60) | `migrate_bookings` | 60 | Loads earlier-version orders without losing them. |
