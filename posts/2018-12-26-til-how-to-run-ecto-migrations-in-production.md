---
author: Kate Travers
author_link: https://github.com/ktravers
categories: til
tags: ['ecto']
date: 2018-12-16
layout: post
title: TIL How to Run Ecto Migrations on Production
excerpt: >
  What to do when you can't use `mix ecto.migrate`
---

You'd think the answer to this question would be a simple Google search away. Unfortunately, that wasn't the case for me this afternoon, working on a Phoenix project with a newly-added Ecto backend. In an effort to save others (and let's be honest, future me) the same frustration, here's the most straight-forward solutions I found.

## What Doesn't Work

[`Mix`](https://elixirschool.com/lessons/basics/mix/). `Mix` tasks aren't compiled into your deployed release, and as evidenced in [this exciting discussion](https://github.com/bitwalker/exrm/issues/67), there's no plans to change this any time soon.

So don't try using your trusty local `mix ecto.migrate` task on production. Not gonna help you here.

## What Does Work

### 1. [Ecto.Migrator](https://hexdocs.pm/ecto/Ecto.Migrator.html)

Ecto ships with [Ecto.Migrator](https://hexdocs.pm/ecto/Ecto.Migrator.html), a first-class module for Ecto's migration API. Run it manually by ssh'ing onto your app server, attaching to your Phoenix app, and running the following:

```elixir
iex> path = Application.app_dir(:my_app, "priv/repo/migrations")
iex> Ecto.Migrator.run(MyApp.Repo, path, :up, all: true)
```

Ideally, you'd wrap up the above in its own task that can be called during your build and deployment process. Check out Plataformatec's blog for a [nice example](http://blog.plataformatec.com.br/2016/04/running-migration-in-an-exrm-release/).

### 2. eDeliver

Our app uses [`edeliver`](https://github.com/edeliver/edeliver) for deployments, and it has a super handy command for manually running migrations:

```shell
mix edeliver migrate production
```

If we peek at the source, turns out this command actually just [wraps up `Ecto.Migrator` for you](https://github.com/edeliver/edeliver/blob/963610a90f67fc3671127e64df37a67ec365ef5b/lib/edeliver.ex#L124), saving some precious keystrokes.

To run successfully, you'll need to add `ECTO_REPOSITORY="MyApp.Repo"` to your `.deliver/config` file.

Again, Plataformatec has a nice blog post on [deploying your Elixir app with eDeliver](http://blog.plataformatec.com.br/2016/06/deploying-elixir-applications-with-edeliver/).

## Summary

Hi future me! Hope this post was still helpful the nth time around.

### References:

- [Phoenix Ecto Integration](https://github.com/phoenixframework/phoenix_ecto)
- [Ecto.Migrator](https://hexdocs.pm/ecto_sql/Ecto.Migrator.html)
- [eDeliver](https://github.com/edeliver/edeliver)
