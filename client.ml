open Lwt
open Dom_html
open Eliom_content.Html5
open React
open Subtitle.Sub

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

let media_init vid =
    let vid_elt = Interface.To_dom.of_video vid in
    let reset_btn_elt = createButton document in
    let export_btn_elt = createButton document in
    let src_input_elt = createInput document in
    let sub_text, send_sub_text = E.create () in
    let _ = E.map edit_sub_text sub_text in

    (* initialization *)
    reset_btn_elt##innerHTML <- Js.string "Reset Source";
    appendWithWrapper document##body reset_btn_elt;
    appendWithWrapper document##body src_input_elt;

    (* wrap video and the subtitle into a div *)
    let div = createDiv document in
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
