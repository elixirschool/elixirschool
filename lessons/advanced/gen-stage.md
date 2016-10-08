---
layout: page
title: GenStage
category: specifics
order: 
lang: en
---

In this lesson we're going to take a closer look at the GenStage, what role it serves, and how we can leverage it in our applications. 

{% include toc.html %}

## Introduction

So what is GenStage?  From the official documentation, it is a "specification and computational flow for Elixir", but what does that mean to us?  

What it means is that GenStage provides a way for us to define a pipeline of work to be carried out by independent steps (or stages) in a separate processes; if you've worked with pipelines before then some of these concepts should be familiar.

To better understand how this works, let's visualize a simple producer-consumer flow:

```
[A] -> [B] -> [C]
```

In this example we have three stages: `A` a producer, `B` a producer-consumer, and `C` a consumer.  `A` produces a value which is consumed by `B`, `B` performs some work and returns a new value which is received by our consumer `C`; the role of our stage is important as we'll see in the next section.

while our example is 1-to-1 producer-to-consumer it's possible to both have multiple producers and multiple consumers at any given stage.

## Consumers and Producers

As we've read, the role we give our stage is important.  The GenStage specification recognizes three roles:

+ `:producer` — A source.  Producers wait for demand from consumers and respond with the requested events.

+ `:producer_consumer` — Both a source and a sink.  Producer-consumers can respond to demand from other consumers as well as request events from producers.

+ `:consumer` — A sink.  A consumer requests and receives data from producers.

Notice that our producers _wait_ for demand?  With GenStage our consumers send demand upstream and process the data from our producer.  This faciliates a mechanism known as back-pressure.  Back-pressure puts the onerous on the producer to not over-pressure when consumers are busy. 

To demostrate a 

## Flow

The best way of think of Flow is as Enum but the computations occur in parallel using GenStages.

### Windows

Windows are data partitions for Flow, with them we can arrange how we accumulate our incoming data.  There are two types of Windows in Flow:

+ Global — The default window.  With a global window, all data belongs to a single window.  There is no partitioning of the data and the window is considered finished only when all producers report no more data.

+ Fixed — Splits data by periodic, non-overlapping windows.  With fixed windows, data can belong to only a single window.

#### Global windows

#### Fixed windows

### Triggers

## Use Cases