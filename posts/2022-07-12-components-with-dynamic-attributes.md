%{
  author: "Tracey Onim",
  author_link: "https://github.com/TraceyOnim",
  tags: ["LiveView", "Components", "LiveView Helpers"],
  date: ~D[2022-07-12],
  title: "Components with dynamic attributes",
  excerpt: """
  Learn how you can support dynamic attributes when using reusable components with assigns_to_attribute/2 function.
  """
}
---


I’m quite sure most of you have already interacted with components. You  may have created components to reuse in your application. However, sometimes you may feel stuck when creating reusable components more so when you want components to meet certain criteria. For example, you may want the feature in component A to be different from that of component B.

What exactly I’m I trying to say? Lets say we are creating an application akin to kanban. I want us to create an application that can help users plan their weekly task.


![board plan](/images/board-plan.png)


From the above image , I have split the board into 3 columns. That is the house, work and school columns. The user interacting with this board is supposed to add weekly task they are supposed to do in each sector.

You will also notice that each sector has a card of different color. I want us to use reusable component to implement in our application. The board will act as the parent LiveView while the card will be the component.

Now that we want the cards in each section to have different colors, how can we make it possible keeping in mind that we are using reusable components.


Let’s begin:

## 1.Create Board LiveView

```elixir
defmodule SampleWeb.BoardLive do
  use  SampleWeb, :live_view

  def mount(_params, _session, socket) do
    work_cards = [
      %{task: "deploy to production", id: "#{1}-work"},
      %{task: "code challenge", id: "#{2}-work"},
      %{task: "plan community events", id: "#{3}-work"}
    ]    

    house_cards = [
      %{task: "wash my dog", id: "#{1}-house"},
      %{task: "sweep the house", id: "#{2}-house"},
      %{task: "tidy my bedroom", id: "#{3}-house"}
    ]    

    school_cards = [
      %{task: "group discussion", id: "#{1}-school"},
      %{task: "submit assignment", id: "#{2}-school"},
      %{task: "work on school project", id: "#{3}-school"}
    ]

    {:ok,
     assign(socket, work_cards: work_cards, house_cards: house_cards, school_cards: school_cards)}

  end

  def render(assigns) do
    ~H"""
    <h1>Board</h1>
    <h2>Weekly Board Task </h2>
    <div class="row">
      <div class="column">
        <h3>Work</h3>
        <%= for card <- @work_cards do %> 
          <.card card={card} />
        <% end %>
       </div>
       <div class="column">
         <h3>House</h3>
         <%= for card <- @house_cards do %> 
           <.card card={card} />
         <% end %>
       </div>
       <div class="column">
         <h3>School</h3>
         <%= for card <- @school_cards do %> 
           <.card card={card} />
         <% end %>
        </div>
      </div>
    """
end

def card(assigns) do
    ~H"""
    <div>
      <div class="column">
        <%= @card.task %>
      </div>
    </div>
    """
  end
end

```

I have created a BoardLive page that renders each card component for house, work and school section.

The card components have been defined using [function components](https://hexdocs.pm/phoenix_live_view/0.16.0/Phoenix.Component.html) mechanism, which is useful for reusing markup in our LiveView.

**NB:** I’m not getting into the details of how the user should add their weekly task. In this example I have hard-coded the task assuming that the user had already added their task. We are actually displaying the task added to the cards .

Our weekly planning task board should look something similar to this when we open our browser:


![board plan output](/images/board-plan-output.png)


## 2.Problem

  1. We want the cards in each section to have a different color from one another . For example, cards in work section can be blue, in house can be green and in school section can be yellow.

  2. Card component defined earlier should also be maintained.


Imagine writing our markup in this manner:

```elixir
    <div class="row">
      <div class="column">
        <h3>Work</h3>
        <%= for card <- @work_cards do %> 
         <div>
          <div class="column bg-blue">
            <%= card.task %>
          </div>
         </div>
        <% end %>
       </div>
       <div class="column">
         <h3>House</h3>
         <%= for card <- @house_cards do %> 
           <div>
            <div class="column bg-green">
             <%= card.task %>
            </div>
          </div>
         <% end %>
       </div>
       <div class="column">
         <h3>School</h3>
         <%= for card <- @school_cards do %> 
          <div>
           <div class="column bg-yellow">
            <%= card.task %>
           </div>
         </div>
         <% end %>
        </div>
      </div>

```

We have solved our first problem , its working but it looks so messed up. Personally, its redundant to write the same markup over and over again and this is the reason why we opted to use function components. However, when we use reusable components we are going back to our previous implementation.

How can we exactly solve this problem?


## 3. Solution

Luckily, in Phoenix LiveView v0.16.0 [assigns_to_attribute/2](https://hexdocs.pm/phoenix_live_view/0.16.0/Phoenix.LiveView.Helpers.html#assigns_to_attributes/2) function was introduced.This function takes in assigns as the first argument and a list of assign’s keys that are to be excluded as the optional second argument.

This function is Useful for transforming caller assigns into dynamic attributes while stripping reserved keys from the result.

Now that we are assured we can transform the assigns passed to card/1 into attributes, let’s go ahead and add class assign and pass bg-* i.e “bg-blue” as the value. “bg-*” represents background color with a css added property.


```elixir
<h3>Work</h3>
<%= for card <- @work_cards do %> 
   <.card card={card} class={"bg-blue"}/>
 <% end %>
.
.
.
 <h3>House</h3>
 <%= for card <- @house_cards do %> 
   <.card card={card} class={"bg-green"}/>
 <% end %>
.
.
.
<h3>School</h3>
<%= for card <- @school_cards do %> 
  <.card card={card} class={"bg-yellow"}/>
<% end %>

```

Inspect the assigns and see what it holds:

```elixir
def card(assigns) do
IO.inspect(assigns, label: "==================card component=====")    

~H"""
    <div>
      <div class="column">
        <%= @card.task %>
      </div>
    </div>
    """
  end

```

```elixir
 output:
==================card component=====: %{
  __changed__: nil,
  card: %{id: "1-work", task: "deploy to production"},
  class: "bg-blue"
}
```

We can see the assigns contains the card and the class assigns. Lets go ahead and invoke the assigns_to_attribute/2 inside the card/1 to transform our class assign for use in `<div>` tag attribute.

```elixir
def card(assigns) do
extra = assigns_to_attributes(assigns)
.
. 
end
```

If we invoke assigns_to_attributes/2 with the assigns, it returns a list of keywords as shown:

```elixir
[
  card: %{id: "3-school", task: "work on school project"},
  class: "column bg-yellow"
]
```

We don’t want to use the card assign as an attribute so we will have to exclude it from the list and only remain with the class assign.

```elixir
def card(assigns) do
extra = assigns_to_attributes(assigns, [:card])
assigns = assign(assigns, :extra, extra)~H"""
    <div>
      <div {@ extra} >
        <%= @card.task %>
      </div>
    </div>
    """
end
```

Next, I have updated our assigns with the attributes(extra) using the [assign/2](https://hexdocs.pm/phoenix_live_view/0.16.0/Phoenix.LiveView.html#assign/2) function .We shall use the @extra to output as HTML attributes on the <div> tag.

**NB:** The component markup has no column class passed to it.I had to remove it there and pass it to class assign when calling the card/1 function.

```elixir
<.card card={card} class={"column bg-green"}/>
```

This is how our rendered markup looks like when you inspect on the browser:

```
<div>
  <div class="column bg-green">
    wash my dog
  </div>
</div>
```

![board plan output2](/images/board-plan-output2.png)
