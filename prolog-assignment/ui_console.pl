:- use_module(library(readutil)).
start :- clock_text(Clock),format('~w~n',[Clock]),write('\nWelcome to Campus Print Shop Advisor — sample prices\n'), main_menu.
main_menu :-
    nl, write('+--------------------------------------+'), nl,
    write('|       CAMPUS PRINT SHOP ADVISOR       |'), nl,
    write('+--------------------------------------+'), nl,
    write('1. New consultation / quotation\n2. View stock\n3. Manage stock\n4. View orders\n5. Cancel order\n6. Reports / concept demo\n0. Exit\n'),
    input('Choice',C),
    (C == end_of_file -> true ; C == 0 -> write('Goodbye.'), nl ;
     safe(menu_action(C)), main_menu).
safe(Goal) :- catch((call(Goal) -> true ; write('No matching result.'),nl),
                         E,(format('Could not complete: ~w~n',[E]))).
% CONCEPT: line-based I/O avoids full stops for everyday input
input(Label,V) :- format('~w: ',[Label]), flush_output,
    read_line_to_string(user_input,Raw),
    (Raw == end_of_file -> V=end_of_file ;
     normalize_space(string(Text),Raw),
     (catch(number_string(N,Text),_,fail) -> V=N ;
      string_lower(Text,Lower), atom_string(V,Lower))).
menu_action(1) :- setup_call_cleanup(new_session(console),consult_console,new_session(console)).
menu_action(2) :- print_stock.
menu_action(3) :- stock_menu.
menu_action(4) :- print_orders.
menu_action(5) :- input('Order number',Id), cancel_order(Id), write('Cancelled; materials returned.'),nl.
menu_action(6) :- reports_menu.
menu_action(C) :- \+ memberchk(C,[1,2,3,4,5,6]), write('Choose 0 to 6.'),nl.
consult_console :- ask_console, request(console,R), session_quotes(console,R,Qs),
    session_reason(console,R,Why), format('~n~w~n',[Why]),
    (Qs == [] -> true ;
     length(Qs,N),format('~d option(s), cheapest first:~n',[N]),
     forall(nth1(I,Qs,Q),(explain(Q,Text),schedule_text(R,Q,Timing),
         format('~d. ~w~n   ~w~n',[I,Text,Timing]))),
     choose_quote(Qs)).
ask_console :-
    (next_question(console,K) -> question(K,Label), input(Label,V),
     (V == end_of_file -> throw(error(input_closed,_)) ;
      valid(K,V) -> put_answer(console,K,V) ; write('Invalid answer; please try again.'),nl),
     ask_console ; true).
choose_quote(Qs) :-
    input('Option number (0 to go back)',I), length(Qs,N),
    (I == 0 -> true ; I == end_of_file -> true ;
     integer(I),between(1,N,I) -> nth1(I,Qs,Q),confirm_prompt(Q) ;
     write('Invalid option.'),nl,choose_quote(Qs)).
confirm_prompt(Q) :- input('Confirm order? (yes/no)',A),
    (A == yes -> confirm(console,Q,Id),format('Order ~d confirmed; stock updated.~n',[Id]),
     booking_text(Id,Timing),format('~w~n',[Timing]);
     memberchk(A,[no,end_of_file]) -> true ;
     write('Enter yes or no.'),nl,confirm_prompt(Q)).
% CONCEPT: fail-driven loop, format/2 aligned tables, write/1 and nl/0
print_stock :- format('~n~w~t~24|~w~n',['Material','Available']),
    stock(M,Q),format('~w~t~24|~d~n',[M,Q]),fail.
print_stock.
print_orders :- order(Id,Q,_),explain(Q,T),booking_text(Id,Timing),
    format('#~d  ~w~n    ~w~n',[Id,T,Timing]),fail.
print_orders :- (\+ order(_,_,_) -> write('No orders yet.'),nl ; true).
stock_menu :-
    write('\nSTOCK: 1 Add | 2 Set quantity | 3 Remove record | 0 Back\n'),input('Choice',C),
    (memberchk(C,[0,end_of_file]) -> true ;
     memberchk(C,[1,2,3]) -> input('Material (paper/staple/spiral)',M),
      (C == 3 -> safe(remove_stock(M)); input('Quantity',Q),
       (C == 1 -> safe(add_stock(M,Q));safe(set_stock(M,Q)))),stock_menu ;
     write('Choose 0 to 3.'),nl,stock_menu).
reports_menu :-
    write('\nREPORTS: 1 Aggregation | 2 Prolog term membership | 0 Back\n'),input('Choice',C),
    (memberchk(C,[0,end_of_file]) -> true ;
     C == 1 -> aggregation_report,reports_menu ;
     C == 2 -> safe(term_demo),reports_menu ;
     write('Choose 0 to 2.'),nl,reports_menu).
aggregation_report :-
    material_occurrences(Ms),format('findall material occurrences: ~w~n',[Ms]),
    (ordered_materials(Set) -> format('setof unique materials: ~w~n',[Set]);
     write('setof fails: no orders.'),nl),
    (orders_by_binding(_,_)->
     forall(orders_by_binding(B,Ids),format('bagof group ~w: ~w~n',[B,Ids]));
     write('bagof fails: no orders; findall returned [].'),nl).
% CONCEPT: read/1 reads a Prolog term, unlike everyday menu input
term_demo :-
    write('Enter a material atom WITH a full stop, e.g. paper. then Enter: '),flush_output,
    read(T),read_line_to_string(user_input,_),
    (ground(T),my_member(T,[paper,staple,spiral]) -> write('Supported material.');
     write('Unknown material.')),nl.
