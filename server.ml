open Common
open Eliom_content
open Html5.D

let bus = Eliom_bus.create Json.t<message>

(* service definitions *)
let main_service =
    Eliom_service.service
    ~path:[]
    ~get_params:Eliom_parameter.unit ()

let simple_service =
    Eliom_service.service
    ~path:["simple"]
    ~get_params:Eliom_parameter.unit ()

let subtitle_service =
    Eliom_service.service
    ~path:["media"]
    ~get_params:Eliom_parameter.unit ()

let caption_service =
    Eliom_service.service
    ~path:["caption"]
    ~get_params:Eliom_parameter.unit ()

let mcq_service =
    Eliom_service.service
    ~path:["mcq"]
    ~get_params:Eliom_parameter.unit ()

let cmt_service =
    Eliom_service.service
    ~path:["comment"]
    ~get_params:Eliom_parameter.unit ()

(* elements *)
let source_input = string_input
    ~a:[a_placeholder "Source text"; a_class ["form-control"]]
    ~input_type:`Text ()

let reactive_input = string_input
    ~a:[a_placeholder "React to the value changes above";
        a_class ["form-control"]]
    ~input_type:`Text ()

let video_player =
    video
    ~srcs:(uri_of_string
        (fun () -> video_url), [])
    ~a:[a_controls (`Controls)]
    [pcdata "Your browser does not support video element"]

(* HTML page contents *)
let skeleton content =
    Lwt.return
    (html
        (head
            (title (pcdata "Ocsigen Reactive Programming"))
            [css_link ~uri:(uri_of_string (fun () -> bootstrap_url))
            ()])
        (body content)
    )

(* home page *)
let main_page =
    skeleton [
        div ~a:[a_class ["container"]] [
        h1 [pcdata "Oreo"];
        p [pcdata "Ocsigen Reactive Programming applications."];
        ul [
        li [a ~service:simple_service [pcdata "Simple example"] ()];
        li [a ~service:subtitle_service [pcdata "Reactive subtitle"] ()];
        li [a ~service:caption_service [pcdata "Caption plug-in"] ()];
        li [a ~service:mcq_service [pcdata "MCQ gadget"] ()];
        li [a ~service:cmt_service [pcdata "Comment helper"] ()];
        ]]
    ]

let simple_example_page =
    skeleton [
        div ~a:[a_class ["container"]] [
            h1 [pcdata "A Simple Example"];
            div ~a:[a_class ["form-group"]] [
                label [pcdata "Input"];
                div [source_input];
            ];
            div ~a:[a_class ["form-group"]] [
                label [pcdata "Reactive output"];
                div [reactive_input]
            ]
        ]
    ]

let subtitle_page =
    skeleton []

let caption_page =
    skeleton []

let mcq_page =
    skeleton []

let cmt_page =
    skeleton []
