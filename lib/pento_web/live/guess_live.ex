defmodule PentoWeb.GuessLive do
  @moduledoc false
  use PentoWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, number: to_string(:rand.uniform(10)), score: 0, message: "Make a guess:")}
  end

  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <h1 class="mb-4 text-4xl font-extrabold">Your score: <%= @score %></h1>
    <h2><%= @message %></h2>
    <br />
    <h2>
      <%= for n <- 1..10 do %>
        <.link
          class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 border border-blue-700 rounded m-1"
          phx-click="guess"
          phx-value-number={n}
        >
          <%= n %>
        </.link>
      <% end %>
    </h2>
    """
  end

  def handle_event("guess", %{"number" => guess}, socket) do
    correct = socket.assigns.number == guess

    message =
      if correct do
        "Your guess: #{guess}. Correct 🎉"
      else
        "Your guess: #{guess}. Wrong. Guess again."
      end

    score =
      if correct do
        socket.assigns.score + 10
      else
        socket.assigns.score - 1
      end

    number =
      if correct do
        to_string(:rand.uniform(10))
      else
        socket.assigns.number
      end

    {:noreply, assign(socket, message: message, score: score, number: number)}
  end
end
