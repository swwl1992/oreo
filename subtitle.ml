open Js
open Dom_html
open Interface

module Sub = struct
    type t = {
        start_t : float;
        end_t : float;
        text : string;
        x: int;
        y: int;
    }

    let sub_lst = ref ([] : t list)
    let id = ref (window##setInterval(Js.wrap_callback
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

    (* add a new subtitle and append to the list *)
    (* input: start_t end_t text *)
    let add_sub st et txt =
        let new_sub = {
            start_t = st;
            end_t = et;
            text = txt;
            x = 0;
            y = 0;
        } in
        sub_lst := (List.append !sub_lst [new_sub])

    (* edit the text *)
    (* input: vid_elt new_text *)
    let edit_sub_text vid_elt new_text =
        let rec find_text vid_elt sub_lst new_text =
            match sub_lst with
            | [] -> []
            | h::t ->
                let curr_t = Js.to_float vid_elt##currentTime in
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
                    new_sub::(find_text vid_elt t new_text)
                else
                    h::(find_text vid_elt t new_text)
        in
        sub_lst := find_text vid_elt !sub_lst new_text


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
        id := Dom_html.window##setInterval(Js.wrap_callback
                (start_cycle_sub vid_elt !sub_div), 50.)

    let remove_sub div =
        Dom_html.window##clearInterval(!id);
        Dom.removeChild div !sub_div;
        sub_lst := []
end
