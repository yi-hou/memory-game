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
  # send the clicked tile information to the server
  def handle_in("clickedOnTile", %{"tile" => tile}, socket) do
     game = Game.clickedOnTile(socket.assigns[:game], tile)
     socket = assign(socket, :game, game)
     Memory.GameBackup.save(socket.assigns[:name], socket.assigns[:game])
     #if both selectedTile1 and selectedTile2 are not nil,
     # send them to checkMatch() to see if they match or not
     if game.selectedTile1 != nil && game.selectedTile2 != nil do
       {:reply, {:checkMatch, %{ "game" => Game.client_view(game) }}, socket}
     # if there's no card being clicked or only one card being clicked,
     # just send ok message to click more tiles.
     else 
       {:reply, {:ok, %{ "game" => Game.client_view(game) }}, socket}
     end
  end
  
  #send the message to check if the two tiles are matched or not
  def handle_in("checkMatch", %{}, socket) do
     game = Game.checkMatch(socket.assigns[:game])
     socket = assign(socket, :game, game)
     Memory.GameBackup.save(socket.assigns[:name], socket.assigns[:game])
     {:reply, {:ok, %{"game" => Game.client_view(game)}}, socket}
  end

  #send the message to reset the game state
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