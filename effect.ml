open Js
open Dom_html
open Common
open Interface

(* helper functions *)
let appendWithWrapper bdy elt =
    let div = createDiv document in
        div##className <- Js.string "form-group";
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
        add_button##className <- Js.string "btn btn-primary";
        st_input##className <- Js.string "form-control";
        et_input##className <- Js.string "form-control";
        txt_textarea##className <- Js.string "form-control";
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
        (* temporarily commented out
        let left = cap.left in
        let top = cap.top in
        *)
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
        sel_elt##className <- Js.string "form-control";
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
        submit_btn##className <- Js.string "btn btn-primary";
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
        id: int; (* unique id starts from 0 *)
        t_stamp: float;
        author: string;
        post_t: string;
        cont: string;
        reply_to: string option;
    }

    let post_id = ref 0
    let reply_to_id = ref (-1)
    let link_id = ref interv_id
    let curr_url = ref ""
    let reply_to = ref ""
    let reply_ind_p = ref (createP document)
    let cmt_lst = ref ([] : t list)
    let cmt_divs = ref ([] : divElement Js.t list)

    (* add some hover effect to comments *)
    let initStyle () =
        let sty_elt = createStyle document in
        let cont = ".comment:hover{border-style:solid}" in
        sty_elt##innerHTML <- Js.string cont;
        Dom.appendChild document##head sty_elt

    (* decide a comment is on top level *)
    let is_top cmt =
        match cmt.reply_to with
        | None -> true
        | Some s -> false

    (* create a link which points to comments *)
    let createCmtLink vid_elt =
        let out_div = createDiv document in
        let cmt_link = createA document in
        out_div##style##position <- Js.string "relative";
        out_div##style##width <- Js.string "200px";
        out_div##style##top <- Js.string "0px";
        out_div##style##height <- Js.string "0px";
        cmt_link##style##fontWeight <- Js.string "bold";
        cmt_link##style##color <- Js.string "white";
        Dom.appendChild out_div cmt_link;
        out_div, cmt_link

    let createCmtDiv vid_elt cmt =
        let div = createDiv document in
        let auth_p = createP document in
        let cont_p = createP document in
        let cont_a = createA document in
        let t_p = createP document in
        let reply_btn = createButton document in
        reply_btn##innerHTML <- Js.string "Reply";
        reply_btn##className <- Js.string "btn btn-primary";
        div##className <- Js.string "comment";
        div##id <- Js.string (string_of_int cmt.id);
        auth_p##innerHTML <- Js.string ("By: "^cmt.author);
        cont_a##innerHTML <- Js.string cmt.cont;
        cont_a##href <- Js.string ("#"^(string_of_int !post_id));
        cont_a##name <- Js.string (string_of_int !post_id);
        incr post_id;
        t_p##innerHTML <- Js.string ("Posted on "^cmt.post_t);
        List.iter (Dom.appendChild div) [cont_p; auth_p; t_p];
        Dom.appendChild cont_p cont_a;
        (* link the div to the time stamp *)
        Lwt.async (fun () ->
            let open Lwt_js_events in
            Lwt.pick [
                clicks div (fun _ _ ->
                    vid_elt##currentTime <- Js.float cmt.t_stamp;
                    Lwt.return ());
                clicks reply_btn (fun _ _ ->
                    (!reply_ind_p)##innerHTML <-
                        Js.string ("Reply to "^cmt.author);
                    reply_to := cmt.author;
                    reply_to_id := cmt.id;
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
        let new_btn = createButton document in
        (* send the info via the bus *)
        let send_cmt reply_to =
            let i = !post_id in
            let ri = !reply_to_id in
            let t = Js.to_float vid##currentTime in
            let a = Js.to_string name_input##value in
            let d_now = jsnew Js.date_now () in
            let d = Js.to_string (d_now##toString()) in
            let c = Js.to_string ta##value in
            let r_to =
                if reply_to = "" then None else Some reply_to in
            let _ = Eliom_bus.write bus (i, ri, t, a, d, c, r_to) in
            ()
        in
        (* search the id in the list of divs *)
        (* and append the cmt_div to the matching div *)
        let rec appendCmt id cmt_div = function
            | [] -> ()
            | h::t ->
                let div_id = int_of_string (Js.to_string h##id) in
                if div_id = id then
                    Dom.appendChild h cmt_div
                else appendCmt id cmt_div t
        in
        (* construction based on info from remote bus *)
        (* ri - reply to id *)
        let construct_rmt_cmt (i, ri, t, a, d, c, r_to) =
            let cmt = {
                id = i;
                t_stamp = t;
                author = a;
                post_t = d;
                cont = c;
                reply_to = r_to;
            } in
            let cmt_div = createCmtDiv vid cmt in
            cmt_div##id <- Js.string (string_of_int cmt.id);
            cmt_lst := !cmt_lst @ [cmt];
            cmt_divs := !cmt_divs @ [cmt_div];
            begin match cmt.reply_to with
            | None -> Dom.appendChild cmts_div cmt_div
            | Some s ->
                (* left indentation *)
                cmt_div##style##marginLeft <- Js.string "75px";
                appendCmt ri cmt_div !cmt_divs
            end
        in
        ta##cols <- 70;
        submit_btn##innerHTML <- Js.string "Submit";
        submit_btn##className <- Js.string "btn btn-info btn-block";
        new_btn##innerHTML <- Js.string "New";
        new_btn##className <- Js.string "btn btn-success btn-block";
        ta##className <- Js.string "form-control";
        name_input##className <- Js.string "form-control";
        Dom.appendChild div !reply_ind_p;
        appendWithWrapper div ta;
        appendWithWrapper div name_input;
        appendWithWrapper div submit_btn;
        appendWithWrapper div new_btn;
        Lwt.async (fun () ->
            let open Lwt_js_events in
            Lwt.pick [
                clicks submit_btn (fun _ _ -> send_cmt !reply_to;
                    Lwt.return ());
                clicks new_btn (fun _ _ ->
                    send_cmt "";
                    (!reply_ind_p)##innerHTML <- Js.string "";
                    Lwt.return ())]);
        Lwt.async (fun () ->
            Lwt_stream.iter construct_rmt_cmt (Eliom_bus.stream bus));
        ta, name_input, submit_btn

    (* return a div to contain all the comments *)
    (* WARNING: ONLY top level comments will be shown *)
    let createCmtsDiv vid_elt =
        let div = createDiv document in
        cmt_divs := List.map (createCmtDiv vid_elt) !cmt_lst;
        (* conditional iteration *)
        let rec con_iter con f l1 l2 =
            match (l1, l2) with
            | ([], []) -> ()
            | (h1::t1, h2::t2) ->
                if (con h1) then f h2 else ();
                con_iter con f t1 t2
            | (_, _) -> ()
        in
        con_iter is_top (Dom.appendChild div) !cmt_lst !cmt_divs;
        div

    (* remove the comments div *)
    let clearCmtDivs out_div div =
        Dom.removeChild out_div div

    (* rebuild the entire comments div based on time *)
    let rebuildCmtsDiv vid_elt cmts_div =
        let cmp a b =
            let curr_t = Js.to_float vid_elt##currentTime in
            let dist_a = abs_float (curr_t -. a.t_stamp) in
            let dist_b = abs_float (curr_t -. b.t_stamp) in
            int_of_float (dist_a -. dist_b)
        in
        let new_cmt_lst = List.sort cmp !cmt_lst in
        (* if new list is diff from old one, reorder the div *)
        if new_cmt_lst = !cmt_lst then () else begin
        cmt_lst := new_cmt_lst;
        let first_cmt = List.nth new_cmt_lst 0 in
        let rec reorder cmt = function
            | [] -> ()
            | h::t ->
                let div_id = int_of_string (Js.to_string h##id) in
                let first_cmt_div = cmts_div##firstChild in
                if div_id = cmt.id && (is_top cmt) then
                    Dom.insertBefore cmts_div h first_cmt_div
                else reorder cmt t
        in
        reorder first_cmt !cmt_divs
        end

    (* display the link inside the element *)
    let startCycleCmt vid_elt cmt_link cmts_div () =
        let rec cycleCmt vid_elt cmt_link cmt_lst =
            let curr_t = Js.to_float vid_elt##currentTime in
            match cmt_lst with
            | [] -> cmt_link##innerHTML <- Js.string "";
            | h::t ->
                let t_stamp = h.t_stamp in
                let id_str = string_of_int h.id in
                if t_stamp -. 0.5 <= curr_t && curr_t <= t_stamp +. 0.5
                then begin
                    cmt_link##innerHTML <- Js.string
                        ("User comment #"^id_str);
                    cmt_link##href <- Js.string ("/comment#"^id_str)
                end
                else
                    cycleCmt vid_elt cmt_link t
        in
        cycleCmt vid_elt cmt_link !cmt_lst;
        rebuildCmtsDiv vid_elt cmts_div

    (* make the comment link appear on the video element *)
    let startLink vid_elt div bus =
        let cmts_div = createCmtsDiv vid_elt in
        (* clearCmtDivs cmts_div; *)
        let _ = appendCmtArea vid_elt div cmts_div bus in
        let out_div, cmt_link = createCmtLink vid_elt in
        Dom.appendChild div cmts_div;
        Dom.insertBefore div out_div (Js.some vid_elt);
        link_id := Dom_html.window##setInterval(Js.wrap_callback
                (startCycleCmt vid_elt cmt_link cmts_div), 50.)
end
