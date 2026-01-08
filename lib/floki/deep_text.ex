defmodule Floki.DeepText do
  @moduledoc false

  # DeepText is a strategy to get text nodes from a HTML tree using a deep search
  # algorithm. It will get all string nodes and concat them.

  @type html_tree :: tuple | list

  @spec get(html_tree, binary, boolean, boolean, boolean) :: binary

  def get(html_tree, sep \\ "", include_inputs? \\ false, js? \\ false, style? \\ true)

  def get(html_tree, sep, include_inputs?, js?, style?) do
    html_tree
    |> get_text([], sep, include_inputs?, js?, style?)
    |> IO.iodata_to_binary()
  end

  defp get_text(nodes, acc, sep, include_inputs?, js?, style?) when is_list(nodes) do
    Enum.reduce(nodes, acc, fn child, istr ->
      get_text(child, istr, sep, include_inputs?, js?, style?)
    end)
  end

  defp get_text(text, [], _sep, _include_inputs?, _js?, _style?) when is_binary(text), do: text

  defp get_text(text, acc, "", _include_inputs?, _js?, _style?) when is_binary(text),
    do: [acc, text]

  defp get_text(text, acc, sep, _include_inputs?, _js?, _style?) when is_binary(text),
    do: [acc, sep, text]

  defp get_text({:comment, _}, acc, _sep, _include_inputs?, _js?, _style?), do: acc

  defp get_text({"br", _, _}, acc, sep, _include_inputs?, _js?, _style?),
    do: add_to_acc(acc, "\n", sep)

  defp get_text({"script", _, _}, acc, _sep, _include_inputs?, false, _style?), do: acc
  defp get_text({"style", _, _}, acc, _sep, _include_inputs?, _js?, false), do: acc

  defp get_text({"input", attrs, _}, acc, sep, true, _js?, _style?) do
    add_to_acc(acc, Floki.TextExtractor.extract_input_value(attrs), sep)
  end

  defp get_text({"textarea", attrs, _}, acc, sep, true, _js?, _style?) do
    add_to_acc(acc, Floki.TextExtractor.extract_input_value(attrs), sep)
  end

  defp get_text({_, _, nodes}, acc, sep, include_inputs?, js?, style?) do
    get_text(nodes, acc, sep, include_inputs?, js?, style?)
  end

  defp get_text(_, acc, _sep, _include_inputs?, _js?, _style?), do: acc

  defp add_to_acc([], text, _sep), do: text
  defp add_to_acc(acc, text, ""), do: [acc, text]
  defp add_to_acc(acc, text, sep), do: [acc, sep, text]
end
