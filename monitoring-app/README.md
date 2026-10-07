# Demo Stop The Crazy Train - Train monitoring app

![lego](https://www.lego.com/cdn/cs/set/assets/blt95604d8cc65e26c4/CITYtrain_Hero-XL-Desktop.png?fit=crop&format=webply&quality=80&width=1600&height=1000&dpr=1)

# Train-Monitoring-App

Train-Monitoring-App is the operator-facing screen for the demo. It tails the annotated
camera frames off Kafka and streams them to a browser, and it provides the buttons that
start and stop capture and the train itself.

It is the last stage of the pipeline in one direction, and the entry point for operator
commands in the other.

## How it works

**Frames in.** `ImageProcessing` consumes the `train-monitoring` Kafka topic, which
`train-ceq-app` produces. Each message is a hand-rolled CloudEvent envelope; the app
reads `data.image` out of the JSON body and pushes it into a `BroadcastProcessor`
exposed as Server-Sent Events on `GET /train-monitoring`. The value is already a
`data:image/webp;base64,...` string, so the browser assigns it straight to an `<img src>`.

Note the Kafka connector is configured with `cloud-events=false` — the envelope is parsed
as ordinary JSON, not by a CloudEvents deserializer.

**Commands out.** `CommandController` exposes five POST endpoints under `/capture`.
**All five do exactly the same thing**: they take the raw request body and emit it to the
`commands-out` Kafka channel, which is the `train-command-capture` topic. The URL path is
effectively decorative.

What actually selects the action is the `command` field *in the body*. `train-ceq-app`'s
second Camel route reads `$.command` and turns it into
`POST ${TRAIN_HTTP_URL}/${command}` against the capture app:

```
browser  --POST /capture/startMovement {"command":"startMovement"}-->  monitoring-app
         --Kafka train-command-capture-->  train-ceq-app
         --POST http://capture-app:8080/capture/startMovement-->  capture-app
```

So a button works only if the body's `command` matches an endpoint that exists on the
capture app. Sending a body without a `command` field breaks the route downstream rather
than here.

## Endpoints

| Endpoint | Purpose |
|---|---|
| `GET /train-monitoring` | SSE stream of annotated frames (`text/event-stream`) |
| `POST /capture/start` | Start camera capture |
| `POST /capture/stop` | Stop camera capture |
| `POST /capture/startMovement` | Start the train (capture app publishes command `2`) |
| `POST /capture/stopMovement` | Stop the train (capture app publishes command `3`) |
| `POST /capture/connectReconnect` | Restart the `train-controller` deployment |

Each `POST` expects a JSON body of the form `{"command": "<name>"}`.

The last three reach code on the capture app that shells out to `oc` and
`mosquitto_pub` — see that repository's README for the caveats, in particular that
`connectReconnect` returns success even when it fails.

## Prerequisites

- **Kafka** — reachable at `KAFKA_BOOTSTRAP_SERVERS` (default `localhost:9092`). Both
  the incoming frame stream and the outgoing commands go through it.

Unlike most of the pipeline this app does **not** talk to MQTT directly.

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `KAFKA_BOOTSTRAP_SERVERS` | `localhost:9092` | Kafka bootstrap servers |
| `KAFKA_TOPIC_MONITORING_NAME` | `train-monitoring` | Topic the annotated frames arrive on |
| `KAFKA_TOPIC_COMMAND_CAPTURE_NAME` | `train-command-capture` | Topic commands are emitted to |
| `SAVE_IMAGE` | `false` | Reserved; the save path is currently commented out in `ImageProcessing` |
| `TMP_FOLDER` | `/tmp/crazy-train-images` | Where frames would be written if saving were enabled |
| `LOGGER_LEVEL` | `INFO` | Root log level |

HTTP port is **8086 in dev mode** and **8080 in the container**.

## How to run

```sh
git clone https://github.com/redhatnsp/train-monitoring-app.git
cd train-monitoring-app/monitoring-app
./mvnw clean quarkus:dev
```

Then open <http://localhost:8086>.

Dev mode needs JDK 17; the Maven wrapper supplies Maven. Kafka must be running — the
maintained local stack is in the
[gitops](https://github.com/redhatnsp/gitops) repository under `podman-compose-shadow/`.

Nothing appears on the page until frames are flowing, which means the whole upstream
pipeline (capture app, intelligent-train, ceq app) has to be running and capture must
have been started.

> In the deployed demo the page is reached at
> `http://monitoring-app-train.apps.example.com`, which requires a matching
> `/etc/hosts` entry. Use Safari — Chrome and Brave force an HTTPS redirect and fail.

## Related Modules

- **Capture-App** — captures frames; receives the commands this app emits.
- **Intelligent-Train** — runs the model over the frames.
- **Train-CEQ-App** — produces the Kafka topic this app consumes, and relays the
  commands this app emits.
- **Train-Controller** — drives the train from those commands.

## Dependencies

- **Quarkus** with SmallRye Reactive Messaging (Kafka connector)
- **Apache Kafka client**
- **CloudEvents SDK**
- **OpenCV** via `quarkus-opencv` (used by `SaveService`)

Managed by Maven in `pom.xml`.

## Known issues

- **A dropped SSE stream freezes the page silently.** `startImageStream()` creates an
  `EventSource` with no `onerror` handler and no reconnect logic, so if the connection
  drops the browser keeps displaying the last frame received with no indication that it
  is stale. There is a `lastImageTime` variable that is assigned on every frame and never
  read — the beginnings of a staleness check that was not finished. On a demo floor this
  looks like a frozen camera rather than a lost connection.
- **The page ships two identical 10.8 MB images.** `background.png` and `train.png` are
  byte-for-byte the same file (both 11,331,986 bytes, same checksum), and both are
  referenced — one from `index.css`, one from `index.html`. `background.png` grew from
  880 KB to 11.3 MB in recent work. That is a lot to pull over the demo WiFi from a
  Jetson, and it is duplicated in the container image as well.
- **The button handlers ignore the response.** None of the `fetch()` calls check status
  or catch errors, so a failed command is invisible in the UI. Combined with the capture
  app returning HTTP 200 on a failed `connectReconnect`, a button can appear to work
  while nothing happened.
- **A malformed Kafka message throws a NullPointerException.** `ImageProcessing` catches
  `JsonMappingException` and `JsonProcessingException`, then dereferences
  `jsonNode.get("data").get("image")` without checking either for null. Both catch blocks
  are still `e.printStackTrace()` with a `// TODO Auto-generated catch block` comment.
- **All five command endpoints are interchangeable.** The path is ignored and the body
  decides, so `POST /capture/stop` with `{"command":"startMovement"}` starts the train.
- This repository contains **two near-identical READMEs**, one at the root and this one.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](../LICENSE)
file for details.
