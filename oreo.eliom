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


let () =
    Oreo_app.register
        ~service:main_service
        (fun () () -> main_page);

    Oreo_app.register
        ~service:simple_service
        (fun () () ->
        ignore{unit{
            simple_example %source_input %reactive_input
        }};
        simple_example_page);

    Oreo_app.register
        ~service:media_service
        (fun () () ->
        ignore{unit{
            media_init %video_player
        }};
        media_page)
