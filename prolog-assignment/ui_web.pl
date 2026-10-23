:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/html_write)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/http_client)).
:- use_module(library(http/http_header)).
:- use_module(library(http/http_session)).
:- use_module(library(uuid)).
:- http_handler(root(.), web_home, []).
:- http_handler(root(action), web_action, [method(post)]).
:- dynamic web_draft/2, web_token/2, web_notice/2.
start_web :- http_server(http_dispatch,[port('127.0.0.1':8080)]),
    format('Open http://localhost:8080~n').
stop_web :- http_stop_server(8080,[]).
web_identity(S,T) :- http_session_id(S),
    with_mutex(print_shop,(web_token(S,T) -> true ; uuid(T),assertz(web_token(S,T)))).
web_home(_) :- web_identity(S,T),
    (retract(web_notice(S,Message)) -> true ; Message=''),shop_page(S,T,Message).
web_action(Request) :-
    web_identity(S,T),
    catch((http_read_data(Request,Data,[]), Form=[search(Data)],
           http_parameters(Form,[token(Given,[]),action(A,[])]),
           (Given == T -> true ; throw(error(invalid_form,_))),
           with_mutex(print_shop,(web_do(A,Form,S,Message) -> true ; throw(error(invalid_action,_))))),
          Error,format(string(Message),'Could not complete: ~w',[Error])),
    retractall(web_notice(S,_)),assertz(web_notice(S,Message)),
    http_redirect(see_other,'/',Request).
web_do(new,_,S,'New consultation started.') :- new_session(S),retractall(web_draft(S,_)).
web_do(answer,Req,S,'Answer saved.') :-
    http_parameters(Req,[key(K,[]),value(Text,[])]),
    (next_question(S,K) -> true ; throw(error(stale_question,_))),
    (catch(atom_number(Text,N),_,fail) -> V=N ; downcase_atom(Text,V)),put_answer(S,K,V).
web_do(confirm,Req,S,Message) :-
    http_parameters(Req,[choice(N,[integer])]),
    (web_draft(S,Qs),integer(N),nth1(N,Qs,Q) -> true ; throw(error(invalid_option,_))),
    confirm(S,Q,Id),retractall(web_draft(S,_)),format(string(Message),'Order ~d confirmed.',[Id]).
web_do(stock,Req,_, 'Stock updated.') :-
    http_parameters(Req,[operation(Op,[]),material(M,[]),quantity(Text,[default('')])]),
    (Op == remove -> remove_stock(M) ;
     (catch(atom_number(Text,Q),_,fail) -> true ; throw(error(invalid_quantity,_))),
     (Op == add -> add_stock(M,Q); Op == set -> set_stock(M,Q);
      throw(error(invalid_operation,_)))).
web_do(cancel,Req,_, 'Order cancelled; stock returned.') :-
    http_parameters(Req,[id(Id,[integer])]),cancel_order(Id).
shop_page(S,T,Message) :-
    with_mutex(print_shop,phrase(content(S,T,Message),Tokens)),
    reply_html_page([title('Campus Print Shop Advisor'),
      meta([name(viewport),content('width=device-width, initial-scale=1')]),
      style('body{font:16px system-ui;max-width:1000px;margin:40px auto;padding:0 20px;background:#f4f7fb;color:#162c40}section{background:white;padding:24px;margin:18px 0;border-radius:16px}button{background:#086b68;color:white;border:0;padding:10px 18px;border-radius:8px;cursor:pointer}input,select{padding:9px;margin:6px}table{width:100%;text-align:left;border-collapse:collapse}td,th{padding:10px;border-bottom:1px solid #ddd}.message{color:#086b68}small{color:#526577}')],\web_tokens(Tokens)).
content(S,T,Message) -->
    {clock_text(Clock)},
    html([h1('Campus Print Shop Advisor'),p('A4 printing • Sample prices and production speeds'),p(Clock),
          p([class(message)],Message),
          section([h2('Consultation'),\form(T,new,[button('Start a new consultation')]),\consultation(S,T)]),
          section([h2('Stock'),\stock_table,\stock_form(T)]),
          section([h2('Orders'),\orders_table,\form(T,cancel,[label('Cancel order number'),input([name(id),type(number),min(1),required]),button('Cancel and return materials')])]),
          section([h2('Reports'),\report_html])]).
form(T,A,Children) --> html(form([action('/action'),method(post)],
    [input([type(hidden),name(token),value(T)]),input([type(hidden),name(action),value(A)])|Children])).
consultation(S,T) -->
    {next_question(S,K),question(K,Label)},!,
    form(T,answer,[p(Label),input([type(hidden),name(key),value(K)]),
         label(['Answer ',input([name(value),required,autocomplete(off)])]),button('Continue')]).
consultation(S,T) -->
    {request(S,R),session_quotes(S,R,Qs),session_reason(S,R,Why),
     retractall(web_draft(S,_)),assertz(web_draft(S,Qs)),
     findall(li(Text),(nth1(I,Qs,Q),explain(Q,E),schedule_text(R,Q,Timing),
       format(string(Text),'Option ~d: ~w ~w',[I,E,Timing])),Rows)},
    html([p(Why),ul(Rows)]),confirm_form(T,Qs).
confirm_form(_,[]) --> [].
confirm_form(T,Qs) --> {length(Qs,N)},
    form(T,confirm,[label('Option number'),input([name(choice),type(number),min(1),max(N),required]),button('Confirm order')]).
stock_table --> {findall(tr([td(M),td(Q)]),stock(M,Q),Rows)},
    html(table([tr([th('Material'),th('Available')])|Rows])).
stock_form(T) --> form(T,stock,[
    label(['Operation ',select([name(operation)],[option([value(add)],'Add'),option([value(set)],'Set'),option([value(remove)],'Remove')])]),
    label(['Material ',select([name(material)],[option(paper),option(staple),option(spiral)])]),
    label(['Quantity ',input([name(quantity),type(number),min(0)])]),button('Update stock')]).
orders_table --> {findall(tr([td(I),td(Text),td(Timing)]),
    (order(I,Q,_),explain(Q,Text),booking_text(I,Timing)),Rows)},
    html(table([tr([th('Order'),th('Details'),th('Schedule')])|Rows])).
report_html --> {material_occurrences(M),term_string(M,MS),
    (ordered_materials(U)->term_string(U,US);US='No solutions (setof fails)'),
    findall(li(Text),(orders_by_binding(B,Ids),format(string(Text),'~w: ~w',[B,Ids])),Groups)},
    html([p(['findall occurrences: ',MS]),p(['setof unique materials: ',US]),
          p('bagof order groups (empty when no orders):'),ul(Groups)]).

web_tokens(Tokens, In, Out) :- append(Tokens,Out,In).
