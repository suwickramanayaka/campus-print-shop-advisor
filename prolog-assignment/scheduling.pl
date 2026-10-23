:- use_module(library(date)).
:- dynamic booking/4, demo_clock/1.
% CONCEPT: facts define one FIFO production station, open every day in Sri Lanka
shop_hours(540,1020).
print_speed(bw,20).
print_speed(colour,10).
bind_minutes(none,0).
bind_minutes(staple,1).
bind_minutes(spiral,3).
now_minute(N) :- demo_clock(N), !.
now_minute(N) :- get_time(T), N is ceiling(T/60).
set_demo_time(Text) :- parse_local(Text,N), retractall(demo_clock(_)), assertz(demo_clock(N)).
use_live_time :- retractall(demo_clock(_)).
local_label(N,Text) :- T is N*60+19800, stamp_date_time(T,D,'UTC'),
    format_time(atom(Text),'%Y-%m-%d %H:%M',D).
parse_local(Text,N) :- atom(Text), atom_length(Text,16),
    atomic_list_concat([Date,Time],' ',Text),
    atomic_list_concat([Date,'T',Time,':00+05:30'],ISO),
    catch(parse_time(ISO,T),_,fail), N is round(T/60), local_label(N,Text).
deadline_value(none,none).
deadline_value(Text,N) :- Text \== none, parse_local(Text,N).
valid_deadline(Text) :- deadline_value(Text,N),
    (N == none -> true ; now_minute(Now), N >= Now).
% CONCEPT: arithmetic and recursion carry production across closed hours
open_minute(N,Start) :- shop_hours(Open,Close), Day is (N+330)//1440,
    Begin is Day*1440+Open-330, End is Day*1440+Close-330,
    (N < Begin -> Start=Begin ; N >= End -> Start is Begin+1440 ; Start=N).
work_finish(N,Minutes,Finish) :- open_minute(N,Start),
    shop_hours(_,Close), End is ((Start+330)//1440)*1440+Close-330,
    Available is End-Start,
    (Minutes =< Available -> Finish is Start+Minutes ;
     Remaining is Minutes-Available, work_finish(End,Remaining,Finish)).
job_minutes(req(P,C,_,_,_,_),quote(_,Colour,_,B,_),Minutes) :-
    print_speed(Colour,Speed), bind_minutes(B,Bind),
    Minutes is 2+(P*C+Speed-1)//Speed+C*Bind.
slot(R,Q,Start,Finish) :- now_minute(Now),
    findall(F,booking(_,_,F,_),Ends), max_list([Now|Ends],Tail),
    open_minute(Tail,Start), job_minutes(R,Q,Minutes), work_finish(Start,Minutes,Finish).
within_deadline(none,_).
within_deadline(D,Finish) :- number(D), Finish =< D.
session_deadline(S,D) :- known(S,deadline,Text), deadline_value(Text,D).
session_quotes(S,R,Qs) :- quotes(R,Base), session_deadline(S,D),
    findall(Q,(member(Q,Base),slot(R,Q,_,Finish),within_deadline(D,Finish)),Qs).
session_reason(S,R,Text) :- quotes(R,Base),
    (Base == [] -> reason(R,Text) ; session_quotes(S,R,Available),
     (Available \= [] -> Text='Options meet your requirements, budget, stock and deadline.' ;
      findall(F,(member(Q,Base),slot(R,Q,_,F)),Ends), min_list(Ends,E),local_label(E,L),
      format(atom(Text),'Deadline cannot be met. Earliest completion: ~w Sri Lanka time. Start a new consultation to choose a later deadline.',[L]))).
schedule_text(R,Q,Text) :- slot(R,Q,Start,Finish),job_minutes(R,Q,M),
    local_label(Start,A),local_label(Finish,B),
    format(atom(Text),'~d working minutes. Start ~w; finish ~w (Sri Lanka).',[M,A,B]).
reserve(S,R,Q,Id) :- session_deadline(S,D),slot(R,Q,A,B),
    (within_deadline(D,B) -> assertz(booking(Id,A,B,D)); throw(error(deadline_no_longer_available,_))).
booking_text(Id,Text) :- booking(Id,A,B,D),local_label(A,Start),local_label(B,End),
    (D == none -> Due='none';local_label(D,Due)),
    format(atom(Text),'Start ~w; finish ~w; deadline ~w (Sri Lanka).',[Start,End,Due]).
can_cancel(Id) :-
    (booking(Id,Start,_,_),now_minute(Now),Now > Start ->
     throw(error(order_already_started,_));true).
migrate_bookings :- forall((order(Id,Q,R),\+ booking(Id,_,_,_)),
    (slot(R,Q,A,B),assertz(booking(Id,A,B,none)))).
clock_text(Text) :- now_minute(N),local_label(N,Now),
    (demo_clock(_) -> Mode='Frozen demo clock';Mode='Live shop clock'),
    format(atom(Text),'~w: ~w Sri Lanka. Hours 09:00-17:00 daily.',[Mode,Now]).
