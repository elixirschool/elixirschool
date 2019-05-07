---
author: Bobby Grayson
categories: general
tags: ['plug']
date: 2019-02-12
layout: post
title: Deploying our `Plug.Router` application to Heroku
excerpt: >
  Want to put your app in the real world? Today we do it with Heroku!
---

In our previous post, [Building web apps with Plug.Router](https://elixirschool.com/blog/building-apps-with-plug-router/) we built a website using just `Plut.Router`.
Today we'll explore how to take the previous app we built and get it up and running on Heroku; this post won't focus on Phoenix deployments.
In this (brief) post, we will show how to get things up and running on [Heroku](http://heroku.com) for a vanilla `Plug` app.
It really is quite easy, but today when I set out to do it, the resources I found either focused on Phoenix or had a few holes, so I figured I would write up a simple one here.
Before we get started, head over to Heroku and make an account as well as install their CLI tools.

## Let's Do It!

To deploy our application to Heroku we'll need to do a few things:

* Add a `Procfile` which tells Heroku what our server process does
* Add buildpacks to our application. These instruct Heroku on how to build our Elixir code.
* Add our environment variables
* Finally, update our `application.ex` code to use the `PORT` variable provided by Heroku

We won't waste too much time on `Procfile` details but simply put they define what our server processes will do. In our case we'll want to run our application in the `web` process. To do that let's create and open `Procfile` in our application root:

```
web: mix run --no-halt
```
We've told Heroku we want our `web` process to execute the `mix run --no-halt` command.
That's it!

Now we can run `heroku create` to make it real.
We have a few more steps before its ready to see live, though.

The joy of using Heroku is that they handle a lot of the work for you with awesome builtin tooling.
One of those features is the `buildpacks` which include instructions for building, in our case compiling, our application code.
For Elixir we'll need to add a specialized `buildpack` that knows how to fetch Elixir dependencies and build that code.

```
heroku buildpacks:set https://github.com/HashNuke/heroku-buildpack-elixir
```

Now we need to setup our environment variables.
For our application we only need to worry about one: `MIX_ENV`.

```
heroku config:set MIX_ENV=prod
```

We also need to give our buildpack some config so it knows what our Elixir/Erlang environments are like.
Put this in a file called `elixir_buildpack.config`.

```
# Erlang version
erlang_version=21.1

# Elixir version
elixir_version=1.8
```

Now we can get it up in the real world:

```
$ git push heroku master && heroku open
```

And after that push succeeds, we can see our portfolio site live and working in the real world.

Happy Hacking!
