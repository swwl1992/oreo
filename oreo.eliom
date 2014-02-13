{shared{
    open Eliom_lib
    open Eliom_content
}}

{client{
    open Client
}}

open Server

module Oreo_app =
    Eliom_registration.App (
        struct
          let application_name = "oreo"
        end)

(* main *)
let () =
    Oreo_app.register
        ~service:main_service
        (fun () () -> main_page);

    Oreo_app.register
        ~service:simple_service
        (fun () () ->
        ignore{unit{ simple_example %source_input %reactive_input }};
        simple_example_page);

    Oreo_app.register
        ~service:subtitle_service
        (fun () () ->
        ignore{unit{ subtitle_init %video_player }};
        subtitle_page);

    Oreo_app.register
        ~service:caption_service
        (fun () () ->
        ignore{unit{ caption_init %video_player }};
        caption_page);

    Oreo_app.register
        ~service:mcq_service
        (fun () () ->
        ignore{unit{ mcq_init %video_player }};
        mcq_page);

    Oreo_app.register
        ~service:cmt_service
        (fun () () ->
        ignore{unit{ comment_init %video_player %bus }};
        cmt_page)
