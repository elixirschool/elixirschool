---
author: Sophie DeBenedetto
author_link: https://github.com/sophiedebenedetto
categories: post
date: 2019-05-24
layout: post
title:  Using Channels with LiveView for Better UX
excerpt: >
  By pairing a custom Phoenix Channel with our LiveView, with the help of a Registry, we can respond to LiveView events with custom JavaScript on the client-side to provide better UX.
---

Building chat app, came up against a limit of LiveView--needed to respond to a LiveView event with a tiny bit of custom JS on the front-end. LiveView JS library doesn't expose such functionality. But, by extending the LiveView socket, building a custom LiveView channel and using a Registry to link the two, I was able to implement this functionality.

## The Problem
- what we need
- why LV can't do it
- before and after giphs

## The Solution
- Extend the LV socket to define a custom channel that client can join on the FE
- Define and start a Registry when the app starts up so that we can store the channel PID under session UUID shared with the LV
- LV look up session PID when it receives the given event from the front-end and `send` a message to the channel to push said event to the client.
- Client can respond to this `channel.on` event with our little bit of custom JS to scroll the chat window down.

### Extending the LV Socket  
- Specify channel
- Custom connect logic to store the session uuid that is shared with the LV
  - session UUID from controller -> LV and LV stores in socket state
  - session UUID on the page in a meta tag, used in socket connect request

The process:
- GET /chats/:id -> controller -> mount LV with the session UUID in LV socket state -> render HTML
- Socket connect -> LV mounts again over WS connection, but session_uuid (along with other state from controller) is cached (?)
- Socket connect -> Extended LV socket connect hits with encoded token with session UUID. Decodes, stores UUID in state.

(Diagram)

### Defining the Custom Channel

- Joining the channel on the FE
- When we join, we want to register the channel PID under a key that the LV can look up--we'll use session UUID

### Building the SessionRegistry
- We'll use a Registry to store channel pids under a key that both the channel and LV know about--session uuid
- start registry with app
- register channel pid on channel join

The Process:
- Channel joins -> grabs session_uuid from socket state and registers its own PID under that key in the SessionRegistry

(Diagram)

*Important to note that storing channel PIDs is not distribution-friendly, BUT since the channel and the LV share a socket, it is guaranteed that these processes are running on the same server.*

### Sending Messages to the Channel from the LV
- When the LV gets an event, update state and re-render
- Broadcast to self so that other LVs can also update state and re-render (sender LV will receive broadcast but is smart enough not to re-render)
- In order to ensure that re-render happens _before_ we send message to channel, LVs will respond to broadcast by _first_ sending a message to themselves to tell the channel. Since a process can only do one thing at a time, this will ensure LVs will finish re-rendering before responding to the message.
- LVs respond to message they just sent themselvs by looking up channel PID under their own session uuid from state under the session registry. Then `send` that PID a message.
- Channel responds to message (`handle_in`) by pushing message to front-end
- On the front-end, `channel.on()` will get invoked, and will fire the callback function that scrolls the chat window down.

(Diagram)
(Giph of final functionality)

## Conclusion
- Is this right? What do we want to see LV as a library become capable of?
