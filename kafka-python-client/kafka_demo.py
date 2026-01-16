#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["kafka-python-ng>=2.2.3"]
# ///
"""
Kafka Demo Script - Demonstrates interaction with a 3-broker Kafka cluster.

This script shows:
1. Connecting to the Kafka cluster
2. Listing topics and cluster metadata
3. Producing messages to a topic
4. Consuming messages from a topic
"""

import json
import time
from datetime import datetime

from kafka import KafkaProducer, KafkaConsumer
from kafka.admin import KafkaAdminClient, NewTopic
from kafka.errors import TopicAlreadyExistsError


# Bootstrap servers for our 3-broker cluster
BOOTSTRAP_SERVERS = ["localhost:9092", "localhost:9192", "localhost:9292"]
DEMO_TOPIC = "demo-messages"


def get_cluster_info():
    """Get information about the Kafka cluster."""
    print("\n" + "=" * 60)
    print("CLUSTER INFORMATION")
    print("=" * 60)

    admin = KafkaAdminClient(bootstrap_servers=BOOTSTRAP_SERVERS)

    # Get cluster metadata
    cluster_metadata = admin._client.cluster
    cluster_id = getattr(cluster_metadata, "_cluster_id", "N/A")
    print(f"\nCluster ID: {cluster_id}")

    # Get broker information
    print("\nBrokers:")
    brokers = cluster_metadata.brokers()
    for broker in brokers:
        print(f"  - Node ID: {broker.nodeId}, Host: {broker.host}, Port: {broker.port}")

    # List topics
    topics = admin.list_topics()
    print(f"\nTopics ({len(topics)}):")
    for topic in sorted(topics):
        if not topic.startswith("_"):  # Skip internal topics
            print(f"  - {topic}")

    admin.close()


def create_topic_if_not_exists():
    """Create the demo topic if it doesn't exist."""
    print("\n" + "=" * 60)
    print("CREATING TOPIC")
    print("=" * 60)

    admin = KafkaAdminClient(bootstrap_servers=BOOTSTRAP_SERVERS)

    topic = NewTopic(
        name=DEMO_TOPIC,
        num_partitions=3,
        replication_factor=3,
    )

    try:
        admin.create_topics([topic])
        print(f"\nTopic '{DEMO_TOPIC}' created successfully!")
    except TopicAlreadyExistsError:
        print(f"\nTopic '{DEMO_TOPIC}' already exists.")

    admin.close()


def produce_messages(num_messages: int = 10):
    """Produce messages to the demo topic."""
    print("\n" + "=" * 60)
    print("PRODUCING MESSAGES")
    print("=" * 60)

    producer = KafkaProducer(
        bootstrap_servers=BOOTSTRAP_SERVERS,
        value_serializer=lambda v: json.dumps(v).encode("utf-8"),
        key_serializer=lambda k: k.encode("utf-8") if k else None,
    )

    print(f"\nSending {num_messages} messages to topic '{DEMO_TOPIC}'...")

    for i in range(num_messages):
        key = f"key-{i % 3}"  # Use 3 different keys to distribute across partitions
        message = {
            "id": i,
            "message": f"Hello from Python! Message #{i}",
            "timestamp": datetime.now().isoformat(),
            "metadata": {
                "producer": "kafka-python-demo",
                "cluster": "3-broker-kraft",
            },
        }

        # Send message and get metadata
        future = producer.send(DEMO_TOPIC, key=key, value=message)
        record_metadata = future.get(timeout=10)

        print(
            f"  Sent message {i}: partition={record_metadata.partition}, "
            f"offset={record_metadata.offset}, key={key}"
        )

    producer.flush()
    producer.close()

    print(f"\nAll {num_messages} messages sent successfully!")


def consume_messages(num_messages: int = 10, timeout_ms: int = 10000):
    """Consume messages from the demo topic."""
    print("\n" + "=" * 60)
    print("CONSUMING MESSAGES")
    print("=" * 60)

    consumer = KafkaConsumer(
        DEMO_TOPIC,
        bootstrap_servers=BOOTSTRAP_SERVERS,
        auto_offset_reset="earliest",
        enable_auto_commit=True,
        group_id="demo-consumer-group",
        value_deserializer=lambda m: json.loads(m.decode("utf-8")),
        key_deserializer=lambda k: k.decode("utf-8") if k else None,
        consumer_timeout_ms=timeout_ms,
    )

    print(f"\nConsuming messages from topic '{DEMO_TOPIC}'...")
    print(f"Consumer group: demo-consumer-group")
    print(f"Timeout: {timeout_ms}ms\n")

    message_count = 0
    for message in consumer:
        print(f"Message received:")
        print(f"  - Partition: {message.partition}")
        print(f"  - Offset: {message.offset}")
        print(f"  - Key: {message.key}")
        print(f"  - Value: {json.dumps(message.value, indent=4)}")
        print()

        message_count += 1
        if message_count >= num_messages:
            break

    consumer.close()

    print(f"Consumed {message_count} messages total.")


def check_consumer_group():
    """Check consumer group status."""
    print("\n" + "=" * 60)
    print("CONSUMER GROUP STATUS")
    print("=" * 60)

    admin = KafkaAdminClient(bootstrap_servers=BOOTSTRAP_SERVERS)

    groups = admin.list_consumer_groups()
    print(f"\nConsumer Groups:")
    for group_id, group_type in groups:
        if not group_id.startswith("_"):
            print(f"  - {group_id} (type: {group_type})")

    admin.close()


def main():
    """Main function to run the demo."""
    print("\n" + "#" * 60)
    print("#" + " " * 58 + "#")
    print("#" + " KAFKA 3-BROKER CLUSTER DEMO ".center(58) + "#")
    print("#" + " " * 58 + "#")
    print("#" * 60)

    # Step 1: Show cluster information
    get_cluster_info()

    # Step 2: Create topic
    create_topic_if_not_exists()

    # Give the topic a moment to be fully created
    time.sleep(1)

    # Step 3: Produce messages
    produce_messages(num_messages=10)

    # Step 4: Consume messages
    consume_messages(num_messages=10)

    # Step 5: Check consumer group
    check_consumer_group()

    print("\n" + "=" * 60)
    print("DEMO COMPLETED SUCCESSFULLY!")
    print("=" * 60)
    print("\nCluster endpoints:")
    print("  - Broker 1: localhost:9092")
    print("  - Broker 2: localhost:9192")
    print("  - Broker 3: localhost:9292")
    print(f"\nBootstrap servers: {','.join(BOOTSTRAP_SERVERS)}")


if __name__ == "__main__":
    main()
