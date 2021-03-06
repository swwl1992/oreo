open Lwt
open Dom_html
open Eliom_content.Html5
open React
open Effect
open Effect.Sub
open Effect.Cap
open Effect.Mcq
open Effect.Cmt

let simple_example source_input reactive_input =
    let src_input_elt = To_dom.of_input source_input in
    let rea_input_elt = To_dom.of_input reactive_input in
    let sync_inputs dest src =
        dest##value <- src##value
    in
    let src, send_src = E.create () in
    let _ = E.map (sync_inputs rea_input_elt) src in
    let run () = send_src src_input_elt in
    let _ = window##setInterval(Js.wrap_callback run, 50.)
    in ()

let subtitle_init vid =
    let vid_elt = Interface.To_dom.of_video vid in
    let reset_btn_elt = createButton document in
    let export_btn_elt = createButton document in
    let src_input_elt = createInput document in
    let sub_text, send_sub_text = E.create () in
    let _ = E.map edit_sub_text sub_text in

    (* initialization *)
    reset_btn_elt##innerHTML <- Js.string "Reset Source";
    reset_btn_elt##className <- Js.string "btn btn-warning";
    src_input_elt##className <- Js.string "form-control";

    (* wrap video and the subtitle into a div *)
    let div = createDiv document in
    let title = createH1 document in
    title##innerHTML <- Js.string "Reactive Subtitle Gadget";
    div##className <- Js.string "container";
    Dom.appendChild div title;
    appendWithWrapper div reset_btn_elt;
    appendWithWrapper div src_input_elt;
    Dom.appendChild div vid_elt;
    Dom.appendChild document##body div;
    let st_input_elt, et_input_elt, txt_textarea_elt, add_btn_elt =
        appendEditor div in

    (* modifying methods *)
    let reset_vid_src vid src =
        vid##src <- src;
        remove_sub div
    in

    let add_subtitle vid_elt div =
        let start_t = float_of_string
            (Js.to_string st_input_elt##value) in
        let end_t = float_of_string
            (Js.to_string et_input_elt##value) in
        let text = Js.to_string txt_textarea_elt##value in
        match !sub_lst with
        | [] ->
            if (add_sub start_t end_t text) then
                start_sub vid_elt div
            else
                Dom_html.window##alert(Js.string "Conflict")
        | h::t ->
            if (add_sub start_t end_t text) then ()
            else
                Dom_html.window##alert(Js.string "Conflict")
    in

    let check_sub txt_textarea_elt () =
        try
            let start_t = float_of_string
                (Js.to_string st_input_elt##value) in
            let end_t = float_of_string
                (Js.to_string et_input_elt##value) in
            let text = Js.to_string txt_textarea_elt##value in
            send_sub_text (start_t, end_t, text)
        with _ ->
            ()
    in

    let _ = Dom_html.window##setInterval(Js.wrap_callback
        (check_sub txt_textarea_elt), 50.)
    in

    (* handle button clicks *)
    Lwt.async
    (fun () ->
        let open Lwt_js_events in
        Lwt.pick[
        clicks reset_btn_elt
            (fun _ _ -> reset_vid_src vid_elt src_input_elt##value;
            Lwt.return ());
        clicks add_btn_elt
            (fun _ _ -> add_subtitle vid_elt div;
            Lwt.return ());
        clicks export_btn_elt
            (fun _ _ -> Firebug.console##log(parse_sub ());
            Lwt.return ());
        ]
    )

let caption_init vid =
    let vid_elt = Interface.To_dom.of_video vid in
    let div = createDiv document in
    let title = createH1 document in
    title##innerHTML <- Js.string "Caption Plug-in";
    div##className <- Js.string "container";
    Dom.appendChild div title;
    Dom.appendChild div vid_elt;
    Dom.appendChild document##body div;
    let cap1 = {
        start_t = 1.;
        Effect.Cap.end_t = 4.;
        text = "A seagull";
        left = 0;
        top = 0;
        opacity = 0.0;
        effect = FadeIn;
    } in
    let cap2 = {
        start_t = 2.;
        Effect.Cap.end_t = 5.;
        text = "Jumps into water";
        left = 0;
        top = 30;
        opacity = 1.0;
        effect = FadeOut;
    } in
    cap_lst := [cap1; cap2];
    startCap vid_elt div

let mcq_init vid =
    let vid_elt = Interface.To_dom.of_video vid in
    let div = createDiv document in
    let title = createH1 document in
    title##innerHTML <- Js.string "MCQ Gadget";
    div##className <- Js.string "container";
    Dom.appendChild div title;
    appendWithWrapper div vid_elt;
    Dom.appendChild document##body div;
    (* mcq initiation *)
    let mcq = {
        start_t = 2.0;
        question = "How many people are there in the world?";
        options = ["5 billion"; "6 billion"; "8 billion"];
        ans = 1;
        attempted = false;
        explanation = "N.A.";
    } in
    mcq_lst := [mcq];
    startMcq vid_elt div

let comment_init vid bus =
    let vid_elt = Interface.To_dom.of_video vid in
    let div = createDiv document in
    let title = createH1 document in
    title##innerHTML <- Js.string "Comment Helper";
    div##className <- Js.string "container";
    Dom.appendChild div title;
    Dom.appendChild div vid_elt;
    Dom.appendChild document##body div;
    (* comments initialization *)
    (* initStyle (); *)
    (* for demo purpose, initialize two comments *)
    let cmt1 = {
        id = 0;
        t_stamp = 1.00;
        author = "Kelvin";
        post_t = "Thu Feb 11 2014 09:33:34 GMT+0800 (SGT)";
        cont = "Why?";
        reply_to = None;
    } in
    let cmt2 = {
        id = 1;
        t_stamp = 5.00;
        author = "Bill";
        post_t = "Thu Feb 11 2014 15:34:03 GMT+0800 (SGT)";
        cont = "I think I know.";
        reply_to = None;
    } in
    cmt_lst := [cmt1; cmt2];
    startLink vid_elt div bus
