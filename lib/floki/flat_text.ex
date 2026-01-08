defmodule Floki.FlatText do
  @moduledoc false

  # FlatText is a strategy to get text nodes from a HTML tree without search deep
  # in the tree. It only gets the text nodes from the first level of nodes.

  @type html_tree :: tuple | list

  @spec get(html_tree, binary, boolean, boolean, boolean) :: binary

  def get(html_nodes, sep \\ "", include_inputs? \\ false, js? \\ false, style? \\ true)

  def get(html_nodes, sep, include_inputs?, js?, style?) when is_list(html_nodes) do
    html_nodes
    |> Enum.reduce([], fn html_node, acc ->
      text_from_node(html_node, acc, 0, sep, include_inputs?, js?, style?)
    end)
    |> IO.iodata_to_binary()
  end

  def get(html_node, sep, include_inputs?, js?, style?) do
    text_from_node(html_node, [], 0, sep, include_inputs?, js?, style?)
    |> IO.iodata_to_binary()
  end

  defp text_from_node({"input", attrs, []}, acc, _, sep, true, _, _) do
    add_to_acc(acc, Floki.TextExtractor.extract_input_value(attrs), sep)
  end

  defp text_from_node({"textarea", attrs, []}, acc, _, sep, true, _, _) do
    add_to_acc(acc, Floki.TextExtractor.extract_input_value(attrs), sep)
  end

  defp text_from_node({"script", _, _}, acc, _, _sep, _include_inputs?, false, _style?), do: acc
  defp text_from_node({"style", _, _}, acc, _, _sep, _include_inputs?, _js?, false), do: acc

  defp text_from_node({_tag, _attrs, html_nodes}, acc, depth, sep, include_inputs?, js?, style?)
       when depth < 1 do
    Enum.reduce(html_nodes, acc, fn html_node, acc ->
      text_from_node(html_node, acc, depth + 1, sep, include_inputs?, js?, style?)
    end)
  end

  defp text_from_node(text, [], _, _sep, _, _, _) when is_binary(text), do: text

  defp text_from_node(text, acc, _, sep, _, _, _) when is_binary(text),
    do: add_to_acc(acc, text, sep)

  defp text_from_node(_, acc, _, _, _, _, _), do: acc

  defp add_to_acc([], text, _sep), do: text
  defp add_to_acc(acc, text, ""), do: [acc, text]
  defp add_to_acc(acc, text, sep), do: [acc, sep, text]
end
