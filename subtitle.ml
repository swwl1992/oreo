open Js
open Dom_html
open Interface

module Sub = struct
    type t = {
        start_t : float;
        end_t : float;
        text : string;
    }

    let sub_lst = ref ([] : t list)
    let sub_id = ref (window##setInterval(Js.wrap_callback
        (fun () -> ()), 999.))
    let sub_div = ref (createDiv document)

    (* helper functions *)
    let appendWithWrapper bdy elt =
        let div = createDiv document in
            Dom.appendChild div elt;
            Dom.appendChild bdy div

    (* creaet a div element to hold the text *)
    (* the div will float right above the video *)
    let createSubDiv vid_elt =
        let sub_div = createDiv document in
        sub_div##style##position <- Js.string "relative";
        sub_div##style##fontWeight <- Js.string "bold";
        sub_div##style##color <- Js.string "white";
        sub_div##style##textAlign <- Js.string "center";
        sub_div##style##width <- Js.string
            ((string_of_int vid_elt##videoWidth)^"px");
        sub_div##style##top <- Js.string
            ((string_of_int (vid_elt##videoHeight - 50))^"px");
        sub_div##style##height <- Js.string "0px";
        sub_div

    (* create a subtitle editor and append it to the wrapper *)
    let appendEditor div =
        let st_input = createInput document in
        let et_input = createInput document in
        let txt_textarea = createTextarea document in
        let add_button = createButton document in
        add_button##innerHTML <- Js.string "Add subtitle";
        appendWithWrapper div st_input;
        appendWithWrapper div et_input;
        appendWithWrapper div txt_textarea;
        appendWithWrapper div add_button;
        st_input, et_input, txt_textarea, add_button

    (* subtitle display function *)
    let display_sub vid_elt div sub =
        let start_t = sub.start_t in
        let end_t = sub.end_t in
        let text = sub.text in
        let curr_t = Js.to_float vid_elt##currentTime in
        if start_t <= curr_t && curr_t <= end_t then
            begin
                div##innerHTML <- Js.string text;
                true
            end
        else
            false

    (* subtitle edition functions *)

    (* detect if there is coflicts between subtitles *)
    let is_conflict sub =
        let rec detect_conflict sub = function
            | [] -> false
            | h::t ->
                let start_t = sub.start_t in
                let end_t = sub.start_t in
                let e_start_t = h.start_t in
                let e_end_t = h.end_t in
                if (start_t >= e_start_t && start_t < e_end_t) ||
                   (e_start_t < end_t && end_t <= e_end_t) ||
                   (e_start_t >= start_t && e_end_t <= end_t) then
                    true
                else
                    detect_conflict sub t
        in
        detect_conflict sub !sub_lst

    (* add a new subtitle and append to the list *)
    (* input: start_t end_t text *)
    let add_sub st et txt =
        let new_sub = {
            start_t = st;
            end_t = et;
            text = txt;
        } in
        if (is_conflict new_sub) then false
        else
            begin
                sub_lst := (List.append !sub_lst [new_sub]);
                true
            end

    (* edit the text *)
    (* input: vid_elt new_text *)
    let edit_sub_text (st, et, new_text) =
        let rec find_text st et new_text = function
            | [] -> []
            | h::t ->
                let _start_t = h.start_t in
                let _end_t = h.end_t in
                if _start_t = st && _end_t = et then
                    let new_sub = {
                        start_t = _start_t;
                        end_t = _end_t;
                        text = new_text;
                    } in
                    new_sub::(find_text st et new_text t)
                else
                    h::(find_text st et new_text t)
        in
        sub_lst := find_text st et new_text !sub_lst

    (* remove a subtitle *)
    let remove_sub st et =
        let rec remove_elt st et = function
        | [] -> []
        | h::t ->
            let _start_t = h.start_t in
            let _end_t = h.end_t in
            if _start_t = st && _end_t = et then
                remove_elt st et t
            else
                h::(remove_elt st et t)
        in
        sub_lst := remove_elt st et !sub_lst

    (* clear all the subtitles *)
    (* but the events are preserved *)
    let clear_sub_lst () =
        sub_lst := []

    (* cycle through all the subtitles and show the correct one *)
    let start_cycle_sub vid_elt div () =
        let rec cycle_sub vid_elt div sub_lst =
            match sub_lst with
            | [] -> div##innerHTML <- Js.string ""
            | h::t ->
                if display_sub vid_elt div h then
                    ()
                else
                    cycle_sub vid_elt div t
        in
        cycle_sub vid_elt div !sub_lst

    (* make the subtitle appear on the video element *)
    let start_sub vid_elt div =
        sub_div := createSubDiv vid_elt;
        Dom.insertBefore div !sub_div (Js.some vid_elt);
        sub_id := Dom_html.window##setInterval(Js.wrap_callback
                (start_cycle_sub vid_elt !sub_div), 50.)

    (* clear all the subtitles and stop the display *)
    let remove_sub div =
        Dom_html.window##clearInterval(!sub_id);
        Dom.removeChild div !sub_div;
        sub_lst := []

    (* parse sub_list into WEBVTT format *)
    let parse_sub () =
        let hdr = "WEBVTT" in
        let arrow = "-->" in
        let result = ref (hdr^"\n") in
        let pack_sub result sub =
            let start_t_str = Printf.sprintf "%.3f" sub.start_t in
            let end_t_str = Printf.sprintf "%.3f" sub.end_t in
            result := !result^start_t_str^" "^arrow^" "^end_t_str^"\n";
            result := !result^sub.text^"\n"
        in
        List.iter (pack_sub result) !sub_lst;
        !result
end

(* Caption module *)
module Cap = struct
    type eff =
        Show |
        FadeIn |
        FadeOut |
        Blink |
        ScrollLeft |
        ScrollRight

    type t = {
        start_t: float;
        end_t: float;
        text: string;
        left: int;
        top: int;
        opacity: float;
        effect: eff;
    }

    let cap_lst = ref ([] : t list)
    let cap_id = ref (window##setInterval(Js.wrap_callback
        (fun () -> ()), 999.))
    let cap_divs = ref ([] : divElement Js.t list)

    (* create div to hold captions *)
    let createCapDiv vid_elt cap =
        let cap_div = createDiv document in
        cap_div##style##position <- Js.string "relative";
        cap_div##style##fontWeight <- Js.string "bold";
        cap_div##style##color <- Js.string "white";
        cap_div##style##height <- Js.string "0px";
        let left_str = string_of_int cap.left in
        let top_str = string_of_int cap.top in
        let opac_str = string_of_float cap.opacity in
        cap_div##style##left <- Js.string (left_str^"px");
        cap_div##style##top <- Js.string (top_str^"px");
        cap_div##style##opacity <- Js.def (Js.string opac_str);
        cap_div

    (* change opacity of a div: increase/decrease *)
    let fadeEffect div text opac =
        div##innerHTML <- Js.string text;
        div##style##opacity <- Js.def
            (Js.string (string_of_float opac))

    let displayCap vid_elt cap_div cap =
        let start_t = cap.start_t in
        let end_t = cap.end_t in
        let text = cap.text in
        let left = cap.left in
        let top = cap.top in
        let opacity = cap.opacity in
        let effect = cap.effect in
        let curr_t = Js.to_float vid_elt##currentTime in
        if start_t <= curr_t && curr_t <= end_t then
            begin
                match effect with
                | FadeIn ->
                    let dur = end_t -. start_t in
                    let opac = (curr_t -. start_t) /. dur in
                    fadeEffect cap_div text opac 
                | FadeOut ->
                    let dur = end_t -. start_t in
                    let opac = 1. -. (curr_t -. start_t) /. dur in
                    fadeEffect cap_div text opac 
                | _ ->
                    cap_div##innerHTML <- Js.string text
            end
        else
            cap_div##innerHTML <- Js.string "" 

    let startCycleCap vid_elt () =
        List.iter2 (displayCap vid_elt) !cap_divs !cap_lst

    (* make the caption appear on the video element *)
    let start_cap vid_elt div =
        cap_divs := List.map (createCapDiv vid_elt) !cap_lst;
        let insertCapDiv cap_div =
            Dom.insertBefore div cap_div (Js.some vid_elt) in
        List.iter insertCapDiv !cap_divs;
        cap_id := Dom_html.window##setInterval(Js.wrap_callback
                (startCycleCap vid_elt), 50.)
end
