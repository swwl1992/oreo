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

## Dependencies
* Ocaml release 4.00.1 or above
* [Opam](http://opam.ocaml.org/) (Ocaml Package Manager)
* [React](http://opam.ocaml.org/pkg/react/react.0.9.4/) (installation from Opam)
* [Ocsigen framework](http://ocsigen.org/) release 3.0 or above (installation from Opam)

## API

* [interface.ml API](https://github.com/swwl1992/oreo/wiki/Interface-API)
* [effect.ml API](https://github.com/swwl1992/oreo/wiki/Effect-API)
  * [Sub module](https://github.com/swwl1992/oreo/wiki/Sub-module-API)
  * [Cap module](https://github.com/swwl1992/oreo/wiki/Cap-module-API)
  * [Mcq module](https://github.com/swwl1992/oreo/wiki/Mcq-module-API)
  * [Cmt module](https://github.com/swwl1992/oreo/wiki/Cmt-module-API)

## Execution
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

## Use it for your own project

**interface.ml** and **subtitle.ml** can be transferred and used for your own project.
You are also welcome to folk this repo and contribute to it.
