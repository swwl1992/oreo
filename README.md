Oreo (Ocaml Reactive)
======
[Reactive programming](http://http://en.wikipedia.org/wiki/Reactive_programming)
is a programming paradigm
oriented around data flows and the propagation of change.
[React](http://http://erratique.ch/software/react)
is a module to allow Ocaml programmers to code in reactive style.
This project illustrates some examples of
how reactive programming can be used in web development.

[Ocsigen](http://ocsigen.org) framework is a web framework written in Ocaml and for Ocaml programmers to
develop web applications.

It also contains a light-weight framework written for Ocsigen framework to write multimedia applications.

### Dependencies
* Ocaml release 4.00.1 or above
* [Opam](http://opam.ocaml.org/) (Ocaml Package Manager)
* [React](http://opam.ocamlpro.com/pkg/react.0.9.4.html) (installation from Opam)
* [Ocsigen framework](http://ocsigen.org/) release 3.0 or above (installation from Opam)

### API
**interface.ml** provides type-safe interface for media elements which Ocsigen framework is lacking right now.

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

`To_dom` function converts HTML5 elements to Javascript DOM elements (Dom_html.element).
One conversion function per source type (stressed by the of_ prefix).
It is written in the way similar to standard Eliom
[To_dom](http://ocsigen.org/eliom/api/client/Eliom_content.Html5.To_dom) API's.

```ocaml
module To_dom : sig ... end
```

```ocaml
val of_audio: Html5_types.audio -> audioElement Js.t
```

```ocaml
val of_audio: Html5_types.audio -> audioElement Js.t
```

**subtitle.ml** contains functions that help generattion and edition of subtitles for a video.
It is not written in reactive style to ease its portability.
```ocaml
module Sub struct ... end
```
`appendWithWrapper` wraps an element with a `div` element and append it to the second parameter.
```ocaml
val appendWithWrapper: #Dom.node Js.t -> #Dom.node Js.t -> unit
```
`createSubDiv` returns a div for subtitle display.
It automatically set the width and height according to the video.
```ocaml
val createDiv: Interface.videoElement Js.t -> Dom_html.divElement Js.t
```

`appendEditor` creates an editor for the video which includes start time, end time, textbox and a button.
```ocaml
val appendEditor #Dom.node Js.t -> Dom_html.inputElement Js.t * Dom_html.inputElement Js.t *
Dom_html.textAreaElement Js.t * Dom_html.buttonElement Js.t
```

`add_sub` add a subtitle to the subtitle list.
```ocaml
val add_sub: float -> float -> string -> unit
```

`edit_sub_text` edit the text of an existing subtitle inside the subtitle list.
```ocaml
val edit_sub_text: float * float * string -> unit
```

`start_sub` initiates a process to continuously display subtitles on the video.
The second parameter is the wrapper element of the video (necessary).
You will need this function when you create the very first subtitle of a video.
The subsequent addition and modification of subtitles will no longer require this function.
```ocaml
val start_sub Interface.videoElement Js.t -> #Dom.node Js.t -> unit
```

`remove_sub` removes the subtitle container, deactivates the display process and clear the entire subtitle list.
Use it ONLY when necessary, for example, resetting to a new video.
The first parameter is the wrapper element of the video (necessary).
```ocaml
val: remove_sub: #Dom.node Js.t -> unit
```

### Execution
Test your application by compiling it and running ocsigenserver locally
```
$ make test.byte (or test.opt)
```

Deploy your project on your system
```
$ sudo make install (or install.byte or install.opt)
```

Run the server on the deployed project
```
$ sudo make run.byte (or run.opt)
```

### Use it for your own project

**interface.ml** and **subtitle.ml** can be transferred and used for your own project.
You are also welcome to folk this repo and contribute to it.
