open Eliom_content
open Html5.D

(* service definitions *)
let main_service =
    Eliom_service.service
    ~path:[]
    ~get_params:Eliom_parameter.unit ()

let simple_service =
    Eliom_service.service
    ~path:["simple"]
    ~get_params:Eliom_parameter.unit ()

let media_service =
    Eliom_service.service
    ~path:["media"]
    ~get_params:Eliom_parameter.unit ()

(* elements *)
let source_input = string_input
    ~a:[a_placeholder "Source text"]
    ~input_type:`Text ()

let reactive_input = string_input
    ~a:[a_placeholder "React to the value changes above"]
    ~input_type:`Text ()

let video_player =
    video
    ~srcs:(uri_of_string
        (fun () ->
            "http://video-js.zencoder.com/oceans-clip.webm"), [])
    ~a:[a_controls (`Controls)]
    [pcdata "Your browser does not support video element"]

(* HTML page contents *)
let skeleton content =
    Lwt.return
    (html
        (head
            (title (pcdata "Ocsigen Reactive Programming")) []
        )
        (body content)
    )
    
let main_page =
    skeleton [
        h1 [pcdata "Oreo"];
        p [pcdata "Ocsigen Reactive Programming applications."];
        ul [
           li [a ~service:simple_service [pcdata "Simple example"] ()];
           li [a ~service:media_service [pcdata "Reactive media"] ()]
        ]
    ]

let simple_example_page =
    skeleton [
        h1 [pcdata "A simple Example"];
        div [source_input];
        div [reactive_input];
    ]

let media_page =
    skeleton [
        h1 [pcdata "Reactive media gadget"]
    ]
