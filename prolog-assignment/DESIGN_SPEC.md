# Agreed design: Campus Print Shop Advisor

A campus print shop collects page count, copies, colour requirement, acceptance of double-sided printing, binding requirement and budget and optional deadline. It enumerates compatible A4 options, prices them, checks stock and returns the cheapest feasible options first. Requirements are never silently relaxed.

Facts: rates, materials, sample binding limits and initial stock. Dynamic facts: session answers, material quantities, confirmed orders, production bookings and next order ID. Rule groups: validation, conditional questions, options, sheet arithmetic, material costing, budget/stock feasibility, explanation, confirmation/cancellation and aggregation.

Question flow: pages → copies → colour required → double-sided acceptable → binding required → binding type only if needed → budget → deadline → options → confirmation. Each session stores one answer per key. New sessions clear answers. Browser sessions use distinct IDs; all interfaces share stock and core rules.

Console menu: consultation, stock view, stock management (add/set/remove), orders, cancellation, reports (aggregation and term-membership demo), exit. Web UI exposes consultation, stock, orders, cancellation and aggregation through SWI-Prolog HTTP libraries.

Included: A4, whole-LKR sample prices, uniform colour mode, single/double-sided printing, none/staple/spiral binding, persistence, invalid input handling, unit tests and demo materials. Deadline checking: one FIFO station, daily 09:00–17:00 hours, sample print/binding speeds, stored start/finish times and confirmation-time rechecks. Excluded: actual document processing, payments, printers, tax, actual production monitoring and production authentication.

Core target: 200–300 lines, excluding interfaces and tests. The detailed concept-to-code map is in DEMO_GUIDE.md.
