:- ensure_loaded(main).
:- use_module(library(plunit)).
:- begin_tests(print_shop).
setup_test :-
    retractall(user:db_path(_)),tmp_file(print_shop,P),assertz(user:db_path(P)),
    user:set_demo_time('2026-10-23 09:00'),user:reset_records,user:new_session(test).
cleanup_test :- user:db_path(P),(exists_file(P)->delete_file(P);true),
    user:new_session(test),user:use_live_time.
answers :- forall(member(K-V,[pages-40,copies-3,colour-no,duplex-yes,bound-yes,binding-spiral,budget-1020,deadline-none]),user:put_answer(test,K,V)).
test(odd_pages_per_copy, [nondet]) :-
    quote(req(5,3,no,yes,none,1000),quote(93,bw,double,none,[paper-9])).
test(sample_total, [nondet]) :-
    quote(req(40,3,no,yes,spiral,1020),quote(1020,bw,double,spiral,[paper-60,spiral-3])).
test(budget_exact,[setup(setup_test),cleanup(cleanup_test)]) :-
    quotes(req(40,3,no,yes,spiral,1020),[quote(1020,bw,double,spiral,[paper-60,spiral-3])]).
test(over_budget,[setup(setup_test),cleanup(cleanup_test)]) :-
    quotes(req(40,3,no,yes,spiral,1000),[]).
test(no_colour_downgrade,[setup(setup_test),cleanup(cleanup_test)]) :-
    quotes(req(40,3,yes,yes,spiral,1020),[]).
test(no_binding_downgrade,[setup(setup_test),cleanup(cleanup_test)]) :-
    quotes(req(40,3,no,yes,spiral,720),[]).
test(binding_limit,[fail]) :- quote(req(41,1,no,no,staple,9999),_).
test(skip_binding,[setup(setup_test),cleanup(cleanup_test)]) :-
    forall(member(K-V,[pages-1,copies-1,colour-no,duplex-no,bound-no]),put_answer(test,K,V)),
    next_question(test,budget).
test(answer_replace,[setup(setup_test),cleanup(cleanup_test)]) :-
    put_answer(test,pages,1),put_answer(test,pages,2),findall(V,answer(test,pages,V),[2]).
test(session_isolation,[setup(setup_test),cleanup(cleanup_test)]) :-
    put_answer(test,pages,2),new_session(other),known(test,pages,2).
test(invalid_numeric,[throws(error(invalid_answer(pages),_))]) :- put_answer(test,pages,abc).
test(zero_pages,[fail]) :- valid(pages,0).
test(decimal_pages,[fail]) :- valid(pages,1.5).
test(confirm_cancel,[setup(setup_test),cleanup(cleanup_test),nondet]) :-
    answers,option(test,1,Q),confirm(test,Q,1),stock(paper,20),stock(spiral,7),
    \+ answer(test,_,_),cancel_order(1),stock(paper,80),stock(spiral,10),\+ order(1,_,_).
test(stale_quote,[setup(setup_test),cleanup(cleanup_test),nondet]) :-
    answers,option(test,1,Q),set_stock(paper,0),
    catch(confirm(test,Q,_),error(quote_no_longer_available,_),true),
    \+ order(_,_,_),stock(spiral,10).
test(empty_aggregation,[setup(setup_test),cleanup(cleanup_test)]) :-
    material_occurrences([]),\+ ordered_materials(_),\+ orders_by_binding(_,_).
test(aggregation_duplicates,[setup(setup_test),cleanup(cleanup_test),nondet]) :-
    answers,option(test,1,Q),confirm(test,Q,1),add_stock(paper,60),
    answers,option(test,1,Q),confirm(test,Q,2),
    material_occurrences([paper,spiral,paper,spiral]),
    ordered_materials([paper,spiral]),orders_by_binding(spiral,[1,2]).
test(persistence,[setup(setup_test),cleanup(cleanup_test),nondet]) :-
    answers,option(test,1,Q),confirm(test,Q,1),remove_stock(staple),
    init_db,stock(paper,20),\+ stock(staple,_),order(1,Q,_),next_id(2).
test(unknown_material,[throws(error(invalid_stock,_))]) :- set_stock(ink,4).
test(negative_stock,[throws(error(invalid_stock,_))]) :- set_stock(paper,-1).
test(unknown_order,[setup(setup_test),cleanup(cleanup_test),throws(error(unknown_order,_))]) :- cancel_order(999).
test(custom_member,[nondet]) :- my_member(spiral,[paper,staple,spiral]).
test(no_member,[fail]) :- my_member(ink,[paper,staple]).
test(shortage_reason,[setup(setup_test),cleanup(cleanup_test),nondet]) :-
    set_stock(paper,0),reason(req(1,1,no,no,none,0),'Required materials are unavailable.').
test(breakdown,[nondet]) :-
    price_breakdown(req(5,3,no,yes,none,1000),quote(93,bw,double,none,[paper-9]),75,[line(paper,9,2,18)]).
test(failed_save_rolls_back,[setup(setup_test),cleanup(cleanup_test),nondet]) :-
    retract(user:db_path(P)),assertz(user:db_path('/nonexistent/print-shop/db.pl')),
    catch(set_stock(paper,1),_,true),stock(paper,80),
    retractall(user:db_path(_)),assertz(user:db_path(P)).


test(job_duration,[nondet]) :-
    job_minutes(req(40,3,no,yes,spiral,1020),quote(1020,bw,double,spiral,[]),17).
test(colour_is_slower,[nondet]) :-
    job_minutes(req(40,3,yes,yes,spiral,2820),quote(2820,colour,double,spiral,[]),23).
test(local_time_roundtrip) :- parse_local('2026-10-23 14:00',N),local_label(N,'2026-10-23 14:00').
test(invalid_calendar_date,[fail]) :- parse_local('2026-02-30 14:00',_).
test(invalid_time,[fail]) :- parse_local('2026-10-23 25:00',_).
test(invalid_deadline,[setup(setup_test),cleanup(cleanup_test),throws(error(invalid_answer(deadline),_))]) :-
    put_answer(test,deadline,'tomorrow afternoon').
test(past_deadline,[setup(setup_test),cleanup(cleanup_test),fail]) :- valid_deadline('2026-10-23 08:59').
test(before_open,[nondet]) :- parse_local('2026-10-23 08:00',N),
    work_finish(N,17,F),local_label(F,'2026-10-23 09:17').
test(overnight_carry,[nondet]) :- parse_local('2026-10-23 16:50',N),
    work_finish(N,17,F),local_label(F,'2026-10-24 09:07').
test(exact_closing,[nondet]) :- parse_local('2026-10-23 16:43',N),
    work_finish(N,17,F),local_label(F,'2026-10-23 17:00').
test(after_close,[nondet]) :- parse_local('2026-10-23 17:00',N),
    work_finish(N,17,F),local_label(F,'2026-10-24 09:17').
test(multiple_days,[nondet]) :- parse_local('2026-10-23 16:00',N),
    work_finish(N,600,F),local_label(F,'2026-10-25 10:00').
test(exact_deadline,[setup(setup_test),cleanup(cleanup_test),nondet]) :-
    answers,put_answer(test,deadline,'2026-10-23 09:17'),option(test,1,Q),confirm(test,Q,1),
    booking(1,_,F,D), F=:=D,local_label(F,'2026-10-23 09:17').
test(impossible_deadline,[setup(setup_test),cleanup(cleanup_test),nondet]) :-
    answers,put_answer(test,deadline,'2026-10-23 09:16'),request(test,R),
    session_quotes(test,R,[]),session_reason(test,R,Text),sub_atom(Text,_,_,_,'09:17').
test(queue_delay,[setup(setup_test),cleanup(cleanup_test),nondet]) :-
    answers,option(test,1,Q),confirm(test,Q,1),add_stock(paper,60),answers,
    put_answer(test,deadline,'2026-10-23 09:20'),request(test,R),session_quotes(test,R,[]),
    slot(R,Q,A,F),local_label(A,'2026-10-23 09:17'),local_label(F,'2026-10-23 09:34').
test(stale_deadline_atomic,[setup(setup_test),cleanup(cleanup_test),nondet]) :-
    answers,put_answer(test,deadline,'2026-10-23 09:20'),option(test,1,Q),
    set_demo_time('2026-10-23 09:10'),
    catch(confirm(test,Q,_),error(deadline_no_longer_available,_),Caught=yes),
    Caught==yes,stock(paper,80),next_id(1),\+ order(_,_,_),\+ booking(_,_,_,_).
test(booking_persistence,[setup(setup_test),cleanup(cleanup_test),nondet]) :-
    answers,put_answer(test,deadline,'2026-10-23 09:20'),option(test,1,Q),confirm(test,Q,1),
    booking(1,A,B,D),init_db,booking(1,A,B,D).
test(cancel_tail_releases_slot,[setup(setup_test),cleanup(cleanup_test),nondet]) :-
    answers,option(test,1,Q),confirm(test,Q,1),add_stock(paper,60),answers,confirm(test,Q,2),
    cancel_order(2),\+ booking(2,_,_,_),answers,request(test,R),slot(R,Q,_,F),
    local_label(F,'2026-10-23 09:34').
test(cancel_keeps_other_promises,[setup(setup_test),cleanup(cleanup_test),nondet]) :-
    answers,option(test,1,Q),confirm(test,Q,1),add_stock(paper,60),answers,confirm(test,Q,2),
    booking(2,A,B,D),cancel_order(1),booking(2,A,B,D).
test(started_order_not_returned,[setup(setup_test),cleanup(cleanup_test),nondet]) :-
    answers,option(test,1,Q),confirm(test,Q,1),set_demo_time('2026-10-23 09:01'),
    catch(cancel_order(1),error(order_already_started,_),Caught=yes),Caught==yes,
    order(1,Q,_),stock(paper,20).
test(legacy_migration,[setup(setup_test),cleanup(cleanup_test),nondet]) :-
    answers,request(test,R),option(test,1,Q),assertz(user:order(7,Q,R)),migrate_bookings,
    booking(7,_,F,none),local_label(F,'2026-10-23 09:17'),migrate_bookings,
    findall(Finish,booking(7,_,Finish,_),[_]).
:- end_tests(print_shop).
