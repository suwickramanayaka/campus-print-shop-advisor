% CONCEPT: dynamic answers; retractall/1 resets one session only
:- dynamic answer/3.
new_session(S) :- retractall(answer(S, _, _)).
% CONCEPT: green cut; a stored answer is unique for each question
known(S, K, V) :- answer(S, K, V), !.
put_answer(S, K, V) :-
    (valid(K, V) -> true ; throw(error(invalid_answer(K), _))),
    retractall(answer(S, K, _)), assertz(answer(S, K, V)).
next_question(S, K) :-
    member(K, [pages,copies,colour,duplex,bound,binding,budget,deadline]),
    \+ known(S, K, _), needed(S, K), !.
needed(S, binding) :- known(S, bound, yes).
needed(_, K) :- K \= binding.
request(S, req(P,C,Colour,D,B,Budget)) :-
    known(S,pages,P), known(S,copies,C), known(S,colour,Colour),
    known(S,duplex,D), known(S,bound,Bound), known(S,budget,Budget),
    (Bound == no -> B = none ; known(S,binding,B)).
valid_request(req(P,C,Col,D,B,Max)) :-
    valid(pages,P), valid(copies,C), valid(colour,Col), valid(duplex,D),
    memberchk(B,[none,staple,spiral,either]), valid(budget,Max).
colour_option(yes, colour).
colour_option(no, bw).
colour_option(no, colour).
side_option(_, single).
side_option(yes, double).
bind_option(either, B) :- member(B,[staple,spiral]).
bind_option(B, B) :- member(B,[none,staple,spiral]).
sheets(single, P, P).
sheets(double, P, N) :- N is (P+1)//2.
% CONCEPT: append/3 combines paper and binding requirements
requirements(none, Sheets, _, [paper-Sheets]).
requirements(B, Sheets, C, Items) :-
    B \= none, append([paper-Sheets], [B-C], Items).
% CONCEPT: head/tail recursion; custom recursive list predicate
costs([], []).
costs([M-Q|Rest], [Cost|Costs]) :-
    material(M, Price), Cost is Q*Price, costs(Rest, Costs).
% CONCEPT: member/2 and a custom membership predicate
my_member(X, [X|_]).
my_member(X, [_|Tail]) :- my_member(X, Tail).
stock_ok([]).
stock_ok([M-Q|Rest]) :- stock(M, Available), Available >= Q, stock_ok(Rest).
quote(R, quote(Total,Colour,Side,B,Items)) :-
    valid_request(R), R = req(P,C,Col,D,Want,_),
    colour_option(Col,Colour), side_option(D,Side), bind_option(Want,B),
    sheets(Side,P,PerCopy), binding(B,Limit), PerCopy =< Limit,
    Sheets is PerCopy*C, requirements(B,Sheets,C,Items),
    % CONCEPT: sum_list/2 and is/2 compute the quote total
    costs(Items,Costs), sum_list(Costs,MaterialCost),
    rate(Colour,Rate), Total is P*C*Rate+MaterialCost.
% CONCEPT: findall/3 returns [] on no solutions; sort/2 orders quotes
quotes(R, Quotes) :-
    R = req(_,_,_,_,_,Budget),
    findall(Q, (quote(R,Q), Q=quote(T,_,_,_,Items),
                T =< Budget, stock_ok(Items)), Raw), sort(Raw,Quotes).
% CONCEPT: red cut; report only the first applicable rejection reason
reason(R, 'Binding capacity is insufficient.') :- \+ quote(R,_), !.
reason(R, 'Required materials are unavailable.') :-
    \+ (quote(R,quote(_,_,_,_,Items)), stock_ok(Items)), !.
reason(R, 'Available options exceed your budget.') :- quotes(R,[]), !.
reason(_, 'Options meet your requirements, budget and current stock.').
% CONCEPT: length/2 and nth1/3 for numbered option selection
option(S, N, Q) :- request(S,R), session_quotes(S,R,Qs), length(Qs,Count),
    integer(N), between(1,Count,N), nth1(N,Qs,Q).
explain(quote(T,C,D,B,Items), Text) :-
    format(string(Text),'~w, ~w-sided, binding: ~w; materials ~w; total LKR ~d.',
           [C,D,B,Items,T]).
% CONCEPT: recursive explanation of material costs
material_lines([], []).
material_lines([M-Q|Rest], [line(M,Q,Unit,Total)|Lines]) :-
    material(M,Unit), Total is Q*Unit,
    material_lines(Rest,Lines).
price_breakdown(R,Q,PrintCost,Lines) :-
    quote(R,Q), R=req(P,C,_,_,_,_),
    Q=quote(_,Colour,_,_,Items),
    rate(Colour,Rate), PrintCost is P*C*Rate,
    material_lines(Items,Lines).
