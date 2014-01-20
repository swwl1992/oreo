open Lwt
open Dom_html
open Eliom_content.Html5
open React
open Subtitle

let simple_example source_input reactive_input =
    let src_input_elt = To_dom.of_input source_input in
    let rea_input_elt = To_dom.of_input reactive_input in
    let sync_inputs dest src =
        dest##value <- src##value
    in
    let src, send_src = E.create () in
    let sync_react = E.map (sync_inputs rea_input_elt) src in
    let run () = send_src src_input_elt in
    let _ = window##setInterval(Js.wrap_callback run, 50.)
    in ()

let media_init vid =
    let vid_elt = Interface.To_dom.of_video vid in
    let reset_btn_elt = createButton document in
    let src_input_elt = createInput document in

    (* initialization *)
    let appendWithWrapper bdy elt =
        let div = createDiv document in
            Dom.appendChild div elt;
            Dom.appendChild bdy div
    in

    reset_btn_elt##innerHTML <- Js.string "Reset Source";
    appendWithWrapper document##body reset_btn_elt;
    appendWithWrapper document##body src_input_elt;

    (* wrap video and the subtitle into a div *)
    let div = createDiv document in
    Dom.appendChild div vid_elt;
    Dom.appendChild document##body div;

    (* modifying methods *)
    let reset_vid_src vid src =
        vid##src <- src
    in

    let sub_lst = ref
        [{start_t = 1.; end_t = 3.; text= "hello"; x = 0; y = 0;}] in

    let id, sub_div = start_sub vid_elt div !sub_lst in

    sub_lst :=
        [{start_t = 1.; end_t = 3.; text= "seven"; x = 0; y = 0;}];

    let iid = reset_sub id vid_elt sub_div !sub_lst in

    (* handle button clicks *)
    Lwt.async
    (fun () ->
        let open Lwt_js_events in
        clicks reset_btn_elt
        (fun _ _ -> reset_vid_src vid_elt src_input_elt##value;
            Lwt.return ()))
