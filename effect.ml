open Js
open Dom_html
open Common
open Interface

(* helper functions *)
let appendWithWrapper bdy elt =
    let div = createDiv document in
        Dom.appendChild div elt;
        Dom.appendChild bdy div

(* used as a reference *)
let interv_id = window##setInterval(Js.wrap_callback
        (fun () -> ()), 999.)

(* Subtitle module *)
module Sub = struct
    type t = {
        start_t : float;
        end_t : float;
        text : string;
    }

    let sub_lst = ref ([] : t list)
    let sub_id = ref interv_id
    let sub_div = ref (createDiv document)

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
    let cap_id = ref interv_id
    let cap_divs = ref ([] : divElement Js.t list)

    (* create div to hold captions *)
    let createCapDiv cap =
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
        let effect = cap.effect in
        let curr_t = Js.to_float vid_elt##currentTime in
        if start_t <= curr_t && curr_t <= end_t then
            begin
                match effect with
                | Show ->
                    cap_div##innerHTML <- Js.string text
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
    let startCap vid_elt div =
        cap_divs := List.map createCapDiv !cap_lst;
        let insertCapDiv cap_div =
            Dom.insertBefore div cap_div (Js.some vid_elt) in
        List.iter insertCapDiv !cap_divs;
        cap_id := Dom_html.window##setInterval(Js.wrap_callback
                (startCycleCap vid_elt), 50.)

    let stopCap () =
        Dom_html.window##clearInterval(!cap_id);
        cap_divs := [];
        cap_lst := []
end

(* Multiple choice question module *)
module Mcq = struct
    type t = {
        start_t: float;
        question: string;
        options: string list;
        ans: int; (* index of the option *)
        attempted: bool;
        explanation: string;
    }

    let mcq_lst = ref ([] : t list)
    let qsn_divs = ref ([] : divElement Js.t list)
    let mcq_id = ref interv_id

    let creaetOptElt opt =
        let opt_elt = createOption document in
        opt_elt##value <- Js.string opt;
        opt_elt##innerHTML <- Js.string opt;
        opt_elt

    let initSelect mcq =
        let opt_lst = List.map creaetOptElt mcq.options in
        let sel_elt = createSelect document in
        List.iter (Dom.appendChild sel_elt) opt_lst;
        sel_elt

    let createMcqDiv vid_elt mcq =
        let sel_elt = initSelect mcq in
        let mcq_div = createDiv document in
        mcq_div##innerHTML <- Js.string mcq.question;
        mcq_div##style##display <- Js.string "none";
        mcq_div##style##fontWeight <- Js.string "bold";
        appendWithWrapper mcq_div sel_elt;
        let submit_btn = createButton document in
        let expln_btn = createButton document in
        let cont_btn = createButton document in
        let ans_p = createP document in
        submit_btn##innerHTML <- Js.string "Submit";
        cont_btn##innerHTML <- Js.string "Continue";
        expln_btn##innerHTML <- Js.string "Show Explanation";
        cont_btn##style##display <- Js.string "none";
        expln_btn##style##display <- Js.string "none";
        Dom.appendChild mcq_div submit_btn;
        Dom.appendChild mcq_div cont_btn;
        Dom.appendChild mcq_div expln_btn;
        Dom.appendChild mcq_div ans_p;
        (* replace the original mcq element from the list *)
        let rec replaceMcq mcq = function
        | [] -> []
        | hd::tl ->
            if hd.start_t = mcq.start_t then
                let new_mcq = {
                    start_t = hd.start_t;
                    question = hd.question;
                    options = hd.options;
                    ans = hd.ans;
                    attempted = true;
                    explanation = hd.explanation;
                } in
                new_mcq::(replaceMcq mcq tl)
            else
                hd::(replaceMcq mcq tl)
        in
        let submitAns node =
            let info =
            if sel_elt##selectedIndex = mcq.ans
            then "Corrected!" else "Wrong." in
            node##innerHTML <- Js.string info;
            cont_btn##style##display <- Js.string "initial";
            expln_btn##style##display <- Js.string "initial";
            let _ = window##setTimeout(Js.wrap_callback
            (fun () ->
                begin
                    mcq_lst := replaceMcq mcq !mcq_lst;
                    vid_elt##play()
                end), 10000.)
            in ()
        in
        let continuePlay () =
            mcq_lst := replaceMcq mcq !mcq_lst;
            vid_elt##play()
        in
        let showExp node mcq =
            node##innerHTML <- Js.string mcq.explanation
        in
        Lwt.async
        (fun () ->
            let open Lwt_js_events in
            Lwt.pick [
            clicks submit_btn
                (fun _ _ -> submitAns ans_p;
                Lwt.return ());
            clicks cont_btn 
                (fun _ _ -> continuePlay ();
                Lwt.return ());
            clicks expln_btn
                (fun _ _ -> showExp ans_p mcq;
                Lwt.return ());
            ]
        );
        mcq_div

    let displayMcq vid_elt mcq_div mcq =
        let attempted = mcq.attempted in
        let start_t = mcq.start_t in
        let end_t = start_t +. 1.0 in
        let curr_t = Js.to_float vid_elt##currentTime in
        if start_t <= curr_t && curr_t <= end_t && attempted = false
        then
            begin
                vid_elt##pause();
                mcq_div##style##display <- Js.string "initial"
            end
        else
            mcq_div##style##display <- Js.string "none"

    let startCycleMcq vid_elt () =
        List.iter2 (displayMcq vid_elt) !qsn_divs !mcq_lst

    let startMcq vid_elt div =
        qsn_divs := List.map (createMcqDiv vid_elt) !mcq_lst;
        List.iter (Dom.appendChild div) !qsn_divs;
        mcq_id := Dom_html.window##setInterval(Js.wrap_callback
                (startCycleMcq vid_elt), 50.)

    let stopMcq () =
        Dom_html.window##clearInterval(!mcq_id);
        qsn_divs := [];
        mcq_lst := []
end

(* Comment module *)
module Cmt = struct
    type t = {
        t_stamp: float;
        author: string;
        post_t: string;
        cont: string;
        reply_to: string option;
    }

    let reply_to = ref ("")
    let cmt_lst = ref ([] : t list)
    let cmt_divs = ref ([] : divElement Js.t list)

    (* add some hover effect to comments *)
    let initStyle () =
        let sty_elt = createStyle document in
        let cont = ".comment:hover{border-style:solid}" in
        sty_elt##innerHTML <- Js.string cont;
        Dom.appendChild document##head sty_elt

    let createCmtDiv vid_elt cmt =
        let div = createDiv document in
        let auth_p = createP document in
        let cont_p = createP document in
        let t_p = createP document in
        let reply_btn = createButton document in
        reply_btn##innerHTML <- Js.string "Reply";
        div##className <- Js.string "comment";
        auth_p##innerHTML <- Js.string ("By: "^cmt.author);
        cont_p##innerHTML <- Js.string cmt.cont;
        t_p##innerHTML <- Js.string ("Posted on "^cmt.post_t);
        List.iter (Dom.appendChild div) [cont_p; auth_p; t_p];
        (* link the div to the time stamp *)
        Lwt.async (fun () ->
            let open Lwt_js_events in
            Lwt.pick [
                clicks div (fun _ _ ->
                    vid_elt##currentTime <- Js.float cmt.t_stamp;
                    Lwt.return ());
                clicks reply_btn(fun _ _ ->
                    reply_to := cmt.author;
                    Lwt.return ())]);
        match cmt.reply_to with
        | Some s ->
            let rpl_p = createP document in
            rpl_p##innerHTML <- Js.string ("Reply to "^s);
            Dom.appendChild div rpl_p;
            Dom.appendChild div reply_btn;
            div
        | None ->
            Dom.appendChild div reply_btn;
            div

    let appendCmtArea vid div cmts_div bus =
        let ta = createTextarea document in
        let name_input = createInput document in
        let submit_btn = createButton document in
        (* construct based on current video *)
        let send_cmt () =
            let t = Js.to_float vid##currentTime in
            let a = Js.to_string name_input##value in
            let d_now = jsnew Js.date_now () in
            let d = Js.to_string (d_now##toString()) in
            let c = Js.to_string ta##value in
            let r_to = 
                if !reply_to = "" then None else Some !reply_to in
            let _ = Eliom_bus.write bus (t, a, d, c, r_to) in
            ()
        in
        (* construction based on info from remote bus *)
        let construct_rmt_cmt (t, a, d, c, r_to) =
            let cmt = {
                t_stamp = t;
                author = a;
                post_t = d;
                cont = c;
                reply_to = r_to;
            } in
            let cmt_div = createCmtDiv vid cmt in
            Dom.appendChild cmts_div cmt_div
        in
        ta##cols <- 70;
        submit_btn##innerHTML <- Js.string "Submit";
        appendWithWrapper div ta;
        appendWithWrapper div name_input;
        appendWithWrapper div submit_btn;
        Lwt.async (fun () ->
            let open Lwt_js_events in
            Lwt.pick [clicks submit_btn (fun _ _ -> send_cmt ();
            Lwt.return ())]);
        Lwt.async (fun () ->
            Lwt_stream.iter construct_rmt_cmt (Eliom_bus.stream bus));
        ta, name_input, submit_btn

    let createCommentsDiv vid_elt =
        let div = createDiv document in
        cmt_divs := List.map (createCmtDiv vid_elt) !cmt_lst;
        List.iter (Dom.appendChild div) !cmt_divs;
        div
end
