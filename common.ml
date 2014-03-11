type message = (int * float * string * string * string * string option)
    deriving (Json)

let video_url = "http://video-js.zencoder.com/oceans-clip.webm"
let bootstrap_url =
    "//netdna.bootstrapcdn.com/bootstrap/3.0.0/css/bootstrap.min.css"
