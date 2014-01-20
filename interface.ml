open Js
open Eliom_content.Html5

class type mediaElement = object
    inherit Dom_html.element

    (* Network state *)
    method src : js_string t prop
    method currentSrc : js_string t readonly_prop
    method networkState : int readonly_prop
    method preload : js_string t prop
    method load : unit meth
    method canPlayType : js_string t -> js_string t meth

    (* Ready state *)
    method readyState : int readonly_prop
    method seeking : bool t readonly_prop

    (* Playback state *)
    method currentTime : float t prop
    method initialTime : float t readonly_prop
    method duration : float t readonly_prop
    method startOffsetTime : date t readonly_prop
    method paused : bool t readonly_prop
    method defaultPlaybackRate : float t prop
    method playbackRate : float t prop
    method ended : bool t readonly_prop
    method autoplay : bool t prop
    method loop : bool t prop

    method play : unit meth
    method pause : unit meth

    (* Media controller *)
    method mediaGroup : js_string t prop

    (* Controls *)
    method controls : bool t prop
    method volume : float t prop
    method muted : bool t prop
    method defaultMuted : bool t prop
    end

    class type audioElement = object
    inherit mediaElement
    end

    class type videoElement = object
    inherit mediaElement

    method width : int prop
    method height : int prop
    method videoWidth : int readonly_prop
    method videoHeight : int readonly_prop
end

(* create element methods *)
let createAudio (doc : Dom_html.document t) : audioElement Js.t =
    Js.Unsafe.coerce (doc##createElement (Js.string "audio"))

let createVideo (doc : Dom_html.document t) : videoElement Js.t =
    Js.Unsafe.coerce (doc##createElement (Js.string "video"))

(* functions to convert video into DOM element *)
module To_dom =
struct
    let of_audio (e: 'a Html5_types.audio elt) : audioElement Js.t =
        Js.Unsafe.coerce (To_dom.of_element e)
    let of_video (e: 'a Html5_types.video elt) : videoElement Js.t =
        Js.Unsafe.coerce (To_dom.of_element e)
end
