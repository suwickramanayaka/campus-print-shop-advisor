:- use_module(library(lists)).
% CONCEPT: facts and rules
rate(bw, 5).
rate(colour, 20).
material(paper, 2).
material(staple, 5).
material(spiral, 100).
binding(none, 10000).
binding(staple, 20).
binding(spiral, 200).
initial_stock(paper, 80).
initial_stock(staple, 30).
initial_stock(spiral, 10).
question(pages, 'Pages per copy (1-1000)').
question(copies, 'Copies (1-100)').
question(colour, 'Is colour required? (yes/no)').
question(duplex, 'Is double-sided acceptable? (yes/no)').
question(bound, 'Is binding required? (yes/no)').
question(binding, 'Required binding (staple/spiral/either)').
question(budget, 'Budget in whole LKR (0-10000000)').
question(deadline, 'Deadline YYYY-MM-DD HH:MM in Sri Lanka, or none').
% CONCEPT: between/3 and comparisons validate bounded numeric input
valid(pages, N) :- integer(N), between(1, 1000, N).
valid(copies, N) :- integer(N), between(1, 100, N).
valid(budget, N) :- integer(N), between(0, 10000000, N).
valid(colour, X) :- memberchk(X, [yes,no]).
valid(duplex, X) :- memberchk(X, [yes,no]).
valid(bound, X) :- memberchk(X, [yes,no]).
valid(binding, X) :- memberchk(X, [staple,spiral,either]).
valid(deadline, Text) :- valid_deadline(Text).
