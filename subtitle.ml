open Js
open Dom_html
open Interface

type t = {
    start_t : float;
    end_t : float;
    text : string;
    x: int;
    y: int;
}

(* creaet a div element to hold the text *)
(* the div will float right above the video *)
let createSubDiv vid_elt =
    let sub_div = createDiv document in
    sub_div##style##position <- Js.string "relative";
    sub_div##style##fontWeight <- Js.string "bold";
    sub_div##style##color <- Js.string "white";
    sub_div##style##textAlign <- Js.string "center";
    sub_div##style##width <-
        Js.string ((string_of_int vid_elt##videoWidth)^"px");
    sub_div##style##top <-
        Js.string ((string_of_int (vid_elt##videoHeight - 65))^"px");
    sub_div##style##height <- Js.string "15px";
    sub_div

(* subtitle display function *)
let display_sub vid_elt div sub =
    let start_t = sub.start_t in
    let end_t = sub.end_t in
    let text = sub.text in
    let curr_t = Js.to_float vid_elt##currentTime in
    Firebug.console##log(vid_elt##currentTime);
    if start_t <= curr_t && curr_t <= end_t then
        begin
            div##innerHTML <- Js.string text;
            true
        end
    else
        false

(* subtitle edition function *)

(* add a new subtitle and append to the list *)
(* input: start_t end_t text *)
(* output: new sub_lst *)
let add_sub st et txt sub_lst =
    let new_sub = {
        start_t = st;
        end_t = et;
        text = txt;
        x = 0;
        y = 0;
    } in
    List.append sub_lst [new_sub]

(* edit the text *)
(* input: vid_elt new_text *)
(* output: new sub_lst *)
let rec edit_sub_text vid_elt new_text = function
    | [] -> []
    | h::t ->
        let curr_t = vid_elt##currentTime in
        let _start_t = h.start_t in
        let _end_t = h.end_t in
        let _x = h.x in
        let _y = h.y in
        if _start_t <= curr_t && curr_t <= _end_t then
            let new_sub = {
                start_t = _start_t;
                end_t = _end_t;
                text = new_text;
                x = _x;
                y = _y
            } in
            new_sub::(edit_sub_text vid_elt new_text t)
        else
            h::(edit_sub_text vid_elt new_text t)

(* cycle through all the subtitles and show the correct one *)
let rec cycle_sub vid_elt div sub_lst () =
    match sub_lst with
    | [] -> div##innerHTML <- Js.string ""
    | h::t ->
        if display_sub vid_elt div h then
            ()
        else
            cycle_sub vid_elt div t ()

(* make the subtitle appear on the video element *)
let start_sub vid_elt div sub_lst =
    let sub_div = createSubDiv vid_elt in
    Dom.appendChild div sub_div;
    let id = Dom_html.window##setInterval(Js.wrap_callback
            (cycle_sub vid_elt sub_div sub_lst), 50.)
    in
    id, sub_div

(* reset the subtitles after edition *)
let reset_sub id vid_elt sub_div sub_lst =
    Dom_html.window##clearInterval(id);
    Dom_html.window##setInterval(Js.wrap_callback
        (cycle_sub vid_elt sub_div sub_lst), 50.)
