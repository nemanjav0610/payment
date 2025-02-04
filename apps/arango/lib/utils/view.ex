defmodule Arango.Utils.View do
  def render_map(data = %{}, view, template) do
    Enum.reduce(data, %{},
     fn({key, val}, acc) ->
       Map.put(acc, key, Phoenix.View.render_one(val, view, template))
     end)
  end
  def render_map(_, _view, _template) do
    %{}
  end
end
