defmodule MemoryWeb.GamesChannel do
  use MemoryWeb, :channel

  alias Memory.Game

  def join("games:" <> name, payload, socket) do
   if authorized?(payload) do
    game = Memory.GameBackup.load(name) || Game.new()
    socket = socket
    |> assign(:game, game)
    |> assign(:name, name)
    {:ok, %{"join" => name, "game" => Game.client_view(game)}, socket}
   else
    {:error, %{reason: "unauthorized"}}
   end
  end

  def handle_in("clickedOnTile", %{"tile" => tile}, socket) do
     game = Game.clickedOnTile(socket.assigns[:game], tile)
     socket = assign(socket, :game, game)
     Memory.GameBackup.save(socket.assigns[:name], socket.assigns[:game])
     if game.selectedTile1 != nil && game.selectedTile2 != nil do
       {:reply, {:checkMatch, %{ "game" => Game.client_view(game) }}, socket}
     else 
       {:reply, {:ok, %{ "game" => Game.client_view(game) }}, socket}
     end
  end
  
  def handle_in("checkMatch", %{}, socket) do
     game = Game.checkMatch(socket.assigns[:game])
     socket = assign(socket, :game, game)
     Memory.GameBackup.save(socket.assigns[:name], socket.assigns[:game])
     {:reply, {:ok, %{"game" => Game.client_view(game)}}, socket}
  end

   def handle_in("new", %{}, socket) do
     game = Game.new()
     Memory.GameBackup.save(socket.assigns[:name], game)
     socket = assign(socket, :game, game)
     {:reply, {:ok, %{"game" => Game.client_view(game)}}, socket}
  end

    def handle_in("ping", payload, socket) do
      {:reply, {:ok, payload}, socket}
    end

    def handle_in("shout", payload, socket) do
      broadcast socket, "shout", payload
      {:noreply, socket}
    end

  defp authorized?(_payload) do
    true
  end
end