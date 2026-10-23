:- use_module(library(filesex)).
% CONCEPT: dynamic database; assertz/1, retract/1 and retractall/1
:- dynamic stock/2, order/3, next_id/1, db_path/1.
:- prolog_load_context(directory, D), directory_file_path(D,'data/db.pl',P),
   assertz(db_path(P)).
reset_records :-
    retractall(stock(_,_)), retractall(order(_,_,_)), retractall(next_id(_)),
    retractall(booking(_,_,_,_)),
    forall(initial_stock(M,Q), assertz(stock(M,Q))), assertz(next_id(1)).
init_db :-
    reset_records, db_path(P),
    (exists_file(P) -> setup_call_cleanup(open(P,read,S),load_records(S),close(S)); true), migrate_bookings.
load_records(S) :-
    read_term(S,T,[]),
    (T == end_of_file -> true ; restore(T), load_records(S)).
restore(stock(M,Q)) :- material(M,_), integer(Q), Q >= 0,
    retractall(stock(M,_)), assertz(stock(M,Q)).
restore(order(I,Q,R)) :- integer(I), I > 0, valid_request(R), quote(R,Q),
    \+ order(I,_,_), assertz(order(I,Q,R)).
restore(next_id(N)) :- integer(N), N > 0,
    retractall(next_id(_)), assertz(next_id(N)).
restore(booking(Id,A,B,D)) :- order(Id,_,_), integer(A),integer(B), B > A,
    (D == none;integer(D),D >= B), assertz(booking(Id,A,B,D)).
restore(removed(M)) :- material(M,_), retractall(stock(M,_)).
save_db :-
    db_path(P), atom_concat(P,'.tmp',Temp),
    setup_call_cleanup(open(Temp,write,S),write_records(S),close(S)),
    rename_file(Temp,P).
write_records(S) :-
    forall(material(M,_),
           (stock(M,Q) -> portray_clause(S,stock(M,Q)); portray_clause(S,removed(M)))),
    forall(order(I,Q,R),portray_clause(S,order(I,Q,R))),
    forall(booking(Id,A,B,D),portray_clause(S,booking(Id,A,B,D))),
    next_id(N), portray_clause(S,next_id(N)).
mutate(Goal) :- with_mutex(print_shop, transaction((call(Goal),save_db))).
set_stock(M,Q) :-
    (material(M,_), integer(Q), between(0,1000000,Q) ->
     mutate((retractall(stock(M,_)),assertz(stock(M,Q)))) ;
     throw(error(invalid_stock,_))).
add_stock(M,Q) :-
    (material(M,_),integer(Q),between(1,1000000,Q) ->
     mutate(add_stock_(M,Q)); throw(error(invalid_stock,_))).
add_stock_(M,Q) :-
    (stock(M,Old) -> true ; Old=0), New is Old+Q,
    (New =< 1000000 -> true ; throw(error(stock_limit,_))),
    retractall(stock(M,_)), assertz(stock(M,New)).
remove_stock(M) :-
    (material(M,_) -> mutate(retractall(stock(M,_))); throw(error(unknown_material,_))).
consume([]).
consume([M-Q|Rest]) :- retract(stock(M,Old)), New is Old-Q,
    assertz(stock(M,New)), consume(Rest).
return_items([]).
return_items([M-Q|Rest]) :-
    (retract(stock(M,Old)) -> true ; Old=0), New is Old+Q,
    assertz(stock(M,New)), return_items(Rest).
confirm(S,Q,Id) :- mutate(confirm_(S,Q,Id)).
confirm_(S,Q,Id) :-
    (request(S,R), quote(R,Q), Q=quote(T,_,_,_,Items),
     R=req(_,_,_,_,_,Budget), T =< Budget, stock_ok(Items) -> true ;
     throw(error(quote_no_longer_available,_))),
    next_id(Id), reserve(S,R,Q,Id),
    consume(Items), retract(next_id(Id)), Next is Id+1,
    assertz(next_id(Next)), assertz(order(Id,Q,R)), new_session(S).
cancel_order(Id) :- mutate(cancel_(Id)).
cancel_(Id) :-
    can_cancel(Id),
    (retract(order(Id,quote(_,_,_,_,Items),_)) ->
     retractall(booking(Id,_,_,_)),return_items(Items) ;
     throw(error(unknown_order,_))).
% CONCEPT: bagof/3 groups by free binding variable; fails if no orders
orders_by_binding(B,Ids) :-
    bagof(Id, T^C^D^Items^R^order(Id,quote(T,C,D,B,Items),R), Ids).
% CONCEPT: setof/3 returns sorted unique materials; fails if no orders
ordered_materials(Materials) :-
    setof(M, Id^T^C^D^B^Items^R^Q^
          (order(Id,quote(T,C,D,B,Items),R),member(M-Q,Items)), Materials).
material_occurrences(Materials) :-
    findall(M,(order(_,quote(_,_,_,_,Items),_),member(M-_,Items)),Materials).
