%{
  author: "Sean Callan",
  author_link: "https://github.com/doomspork",
  date: ~D[2018-10-22],
  tags: ["umbrella applications", "software design", "general"],
  title: "",
  excerpt: """
  A look at umbrella applications and how they can help us write cleaner maintainable code.
  """
}

---

The umbrella application is a powerful tool available to us that a lot of users are unfamiliar with.
In this post we'll look at umbrella applications and why we might want to consider using them for our next project.

## Project types

Before we can understand when to use umbrellas and the role they play, let's review the types of projects available.
For all intents and purposes there are three project types in the Erlang and Elixir ecosystem: Applications, Libraries, and umbrellas which are composed of the prior two.

Libraries are packages of code that can be re-used by other projects and applications.
In Elixir a Library would lack the `:mod` key in the Mix `application/0` function and would also lack a supervision tree.

Applications are like Libraries but contain a supervision tree.
If you open the `mix.exs` file for a project and see that the `application/0` function defines a `:mod` entry point: you're working with an Application.
This is a dependency that has, and maintains, state in addition to processes.
An Application isn't simply a module with simple functions.

Lastly we have umbrella applications which are little more than syntactic sugar for managing a collection of Libraries and Applications as a single project.
Why we might use umbrellas is what we'll explore here today.

## Getting to know umbrella Applications

If you haven't already, take a peek at the [umbrella projects](/en/lessons/advanced/umbrella-projects/) lesson, which provides a great overview of Umbrella applications.

## Separating concerns

In my humble opinion one of the great strengths of umbrellas is the forced separation of concerns and decoupling of code.
We have to be explicit with our individual application's configuration and this includes dependencies on other peer applications.
If our presentation layer doesn't have the internal data application as a dependency there's no chance those two components will become coupled.

While the same separation can be achieved in theory using a singular Application, the umbrella gives us the added benefit of enforcing it through dependencies.
I've never seen "in theory" stand-up in a professional setting when skill levels and experience vary, umbrellas remove any questions and confusion.

Above any other reason, this is often the deciding factor for whether or not I leverage an umbrella application.

## Service Oriented Architecture lite

If we know we are building a complex application with internal components that will grow in size with distinct roles and responsibilities, umbrellas can be a valuable tool in the toolchest.

With one codebase and repository we're able to maintain any number of sub applications as part of our overall umbrella.
If we're building an online marketplace we could use this to keep our payment transaction code isolated from our other modules.
We can implement integrations with third-party services as standalone applications inside our umbrella.
This not only keeps those concerns separated but allows us to work on components individually and more importantly: test them individually.

Nothing is keeping us from running multiple Phoenix applications in a single umbrella.
We can develop our admin web portal independently of our customer facing site, running on a separate port making it a matter of network configuration to limit access to VPN users only.

If the scope of an application grows too much that we need to remove it from the umbrella, no problem!
Doing this is simple with umbrellas because of those explicit dependencies, updating those references is all we need to do.

An added benefit of developing our project as disparate micro-services: large teams can work concurrently on one codebase while minimizing code conflicts.

## One deployment to rule them all

What's easier: deploying changes to 12 applications or 1?

Releases aren't just easier with umbrellas, they're more powerful.
We not only have a single artifact we can deploy, we only have a single service to manage with `systemd` (or the tool of your choice).
There's the additional benefit of no complex orchestration for releasing our different applications.

That's not all.  With Distillery we're able to configure our release artifact to contain all of our applications or just a subset.
Think about that for a moment: we still benefit from working in a single code base but our app separation allows us to deploy any combination of those applications (so long as all dependencies are accounted for).

Our releases can begin life as a single artifact and as needs demands it, we can break out components for independent release.

## To umbrella or not to Umbrella

Contrary to what some may believe, umbrella applications aren't a perfect solution for every problem.
Before we `mix new` we should pause and consider some simple rules to help guide our decision making process:

- Is your application likely to grow in scope and size quickly?
- Are there multiple distinct and separate internal components to our application?
- Will multiple people be working on different parts of the code at once?

If we've answered YES to the above then an umbrella might be the right choice for your project.

We'd love to hear your thoughts!
Are you using umbrella applications?
Have you found them helpful or a hinderance?

Look for our future blog posts that'll cover designing and building your application as an umbrella!
