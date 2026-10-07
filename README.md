# Demo Stop The Crazy Train - Train monitoring app

![lego](https://www.lego.com/cdn/cs/set/assets/blt95604d8cc65e26c4/CITYtrain_Hero-XL-Desktop.png?fit=crop&format=webply&quality=80&width=1600&height=1000&dpr=1)

# Train-Monitoring-App

Train-Monitoring-App is a module in a larger system that is responsible for monitoring and visualization of the train's operation.

> The detailed documentation lives in [`monitoring-app/README.md`](monitoring-app/README.md) —
> endpoints, configuration, how the command flow works, and known issues. This file is a
> summary; prefer the other one if the two disagree.

## How it works

Train-Monitoring-App receives a CloudEvent from the Train-CEQ-App module via Kafka. This CloudEvent contains actionable insights derived from the raw predictions made by the Intelligent-Train module, along with the original images. The Train-Monitoring-App uses this information for monitoring and visualization purposes.

## Prerequisites

- **Kafka**: Train-Monitoring-App uses Kafka to receive data from the Train-CEQ-App module. You need to have a Kafka cluster running and accessible to Train-Monitoring-App. The Kafka cluster's URL should be specified in the `kafka.bootstrap.servers` property in the `application.properties` file.

## Dependencies

Train-Monitoring-App has the following dependencies:

- **Quarkus**: A Kubernetes-native Java stack tailored for GraalVM and OpenJDK HotSpot.
- **Apache Kafka Client**: A client library for Apache Kafka.
- **CloudEvents SDK**: A Java SDK for CloudEvents.

These dependencies are managed by Maven and are specified in the `pom.xml` file.

## Related Modules

Train-Monitoring-App is part of a larger system that includes the following modules:

- **Capture-App**: This module captures video and sends it to Intelligent-Train.
- **Intelligent-Train**: This module uses machine learning algorithms to make decisions based on the data received from the Capture-App.
- **Train-CEQ-App**: This module processes the raw predictions made by the Intelligent-Train module, transforming them into actionable insights.
- **Train-Controller**: This module receives decisions from Train-CEQ-App and controls the operation of the train accordingly.

## How to run

1. Clone the repository: `git clone https://github.com/redhatnsp/train-monitoring-app.git`
2. Navigate to the project directory: `cd monitoring-app`
3. Update the `application.properties` file with the appropriate values.
4. Run the application: `./mvnw clean quarkus:dev`
5. Go to http://localhost:8086

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.