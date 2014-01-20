Oreo (Ocaml Reactive)
======
[Reactive programming](http://http://en.wikipedia.org/wiki/Reactive_programming)
is a programming paradigm
oriented around data flows and the propagation of change.
[React](http://http://erratique.ch/software/react)
is a module to allow Ocaml programmers to code in reactive style.
This project illustrates some examples of
how reactive programming can be used in web development.

It also contains a light weight framework written for [Ocsigen](http://ocsigen.org)
framework to write multimedia applications.
Ocsigen framework is a web framework written in Ocaml and for Ocaml programmers to
develop web applications.

### Dependencies
* Ocaml release 4.0.1 or above
* [Opam](http://opam.ocaml.org/) - Ocaml Package Manager
* [React](http://opam.ocamlpro.com/pkg/react.0.9.4.html) (installation from Opam preferred)
* [Ocsigen framework](http://ocsigen.org/) release 3.0 or above (installation from Opam preferred)

### API
`interface.ml` provides type-safe interface for media elements which Ocsigen framework is lacking right now.

`mediaElement` is a generic media element in DOM.
```ocaml
class type mediaElement = object ... end
```
```ocaml
inherit Dom_html.element

method src : js_string t prop
method currentSrc : js_string t readonly_prop
method networkState : int readonly_prop
method preload : js_string t prop
method load : unit meth
method canPlayType : js_string t -> js_string t meth

method readyState : int readonly_prop
method seeking : bool t readonly_prop

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

method mediaGroup : js_string t prop

method controls : bool t prop
method volume : float t prop
method muted : bool t prop
method defaultMuted : bool t prop
```

```ocaml
class type audioElement = object
    inherit mediaElement
end
```
```ocaml
class type videoElement = object ... end
```
```ocaml
inherit mediaElement

method width : int prop
method height : int prop
method videoWidth : int readonly_prop
method videoHeight : int readonly_prop
```
Create `audioElement` from document object.

```ocaml
val createAudio: document Js.t -> audioElement Js.t
```
Create `videoElement` from document object.

```ocaml
val createVideo: document Js.t -> videoElement Js.t
```

`To_dom` converts HTML5 elements to Javascript DOM elements (Dom_html.element).
One conversion function per source type (stressed by the of_ prefix).
It is written in the way similar to Eliom [To_dom](http://ocsigen.org/eliom/api/client/Eliom_content.Html5.To_dom) API's.

```ocaml
module To_dom : sig ... end
```

```ocaml
val of_audio: Html5_types.audio -> audioElement Js.t
```

```ocaml
val of_audio: Html5_types.audio -> audioElement Js.t
```

### Execution

### Use it for your own project
