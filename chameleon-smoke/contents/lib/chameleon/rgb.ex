defmodule Chameleon.Rgb do
  alias Chameleon.{Hex, Util}

  @doc """
  Converts an rgb color to its hex value.

  ## Examples
      iex> Chameleon.Rgb.to_hex([255, 0, 0])
      "FF0000"
  """
  @spec to_hex(list(integer)) :: charlist
  def to_hex(value) do
    Enum.map(value, fn(dec) -> Integer.to_string(dec, 16) |> String.pad_leading(2, "0") end) |> Enum.join
  end

  @doc """
  Converts an rgb color to its cmyk value.

  ## Examples
      iex> Chameleon.Rgb.to_cmyk([255, 0, 0])
      %{c: 0, m: 100, y: 100, k: 0}
  """
  @spec to_cmyk(list(integer)) :: list(integer)
  def to_cmyk(value) do
    adjusted_rgb = Enum.map(value, fn(v) -> v / 255.0 end)
    k = calculate_black_level(adjusted_rgb)
    [c, m, y] = calculate_cmy(adjusted_rgb, k)
    %{c: round(c * 100),
      m: round(m * 100),
      y: round(y * 100),
      k: round(k * 100)}
  end

  @doc """
  Converts an rgb color to its hsl value.

  ## Examples
      iex> Chameleon.Rgb.to_hsl([255, 0, 0])
      %{h: 0, s: 100, l: 50}
  """
  @spec to_hsl(list(integer)) :: list(integer)
  def to_hsl(value) do
    adjusted_rgb = Enum.map(value, fn(v) -> v / 255.0 end)
    {rgb_min, rgb_max} = Enum.min_max(adjusted_rgb)
    delta = rgb_max - rgb_min
    h = calculate_hue(delta, rgb_max, adjusted_rgb)
    l = calculate_lightness(rgb_max, rgb_min)
    s = calculate_saturation(rgb_max, rgb_min)
    %{h: round(h), s: round(s), l: round(l)}
  end

  @doc """
  Converts an rgb color to its keyword value.

  ## Examples
      iex> Chameleon.Rgb.to_keyword([255, 0, 0])
      "red"

      iex> Chameleon.Rgb.to_keyword([255, 75, 42])
      {:error, "No keyword match could be found for that rgb value."}
  """
  @spec to_keyword(list(integer)) :: charlist
  def to_keyword(value) do
    keyword_to_rgb_map()
    |> Enum.find(fn {_k, v} -> v == value end)
    |> case do
         {keyword, _rgb} -> keyword
         _ -> {:error, "No keyword match could be found for that rgb value."}
    end
  end

  @doc """
  Converts an rgb color to its pantone value.

  ## Examples
      iex> Chameleon.Rgb.to_pantone([0, 0, 0])
      "30"
  """
  @spec to_pantone(list(integer)) :: charlist
  def to_pantone(value) do
    to_hex(value)
    |> Hex.to_pantone
  end

  #### Helper Functions #######################################################################

  defdelegate keyword_to_rgb_map, to: Util

  defp calculate_black_level(rgb) do
    1.0 - Enum.max(rgb)
  end

  defp calculate_cmy(_rgb, 1.0) do
    [0.0, 0.0, 0.0]
  end

  defp calculate_cmy(rgb, black) do
    c = (1.0 - Enum.at(rgb, 0) - black) / (1.0 - black)
    m = (1.0 - Enum.at(rgb, 1) - black) / (1.0 - black)
    y = (1.0 - Enum.at(rgb, 2) - black) / (1.0 - black)
    [c, m, y]
  end

  defp calculate_hue(0, _rgb_max, _rgb), do: 0
  defp calculate_hue(0.0, _rgb_max, _rgb), do: 0

  defp calculate_hue(delta, rgb_max, rgb) do
    [r, g, b] = rgb
    h = cond do
      rgb_max == r ->
        offset = if (g < b), do: 6, else: 0
        60.0 * (((g - b) / delta) + offset)
      rgb_max == g ->
        60.0 * (((b - r) / delta) + 2)
      rgb_max == b ->
        60.0 * (((r - g) / delta) + 4)
      true ->
        0
    end
    Float.round(h)
  end

  defp calculate_lightness(rgb_max, rgb_min) do
    ((rgb_max + rgb_min) / 2) * 100
    |> Float.round()
  end

  defp calculate_saturation(rgb_max, rgb_min) when rgb_max - rgb_min == 0, do: 0

  defp calculate_saturation(rgb_max, rgb_min) do
    l = (rgb_max + rgb_min) / 2
    ((rgb_max - rgb_min) / (1 - :erlang.abs(2 * l - 1))) * 100.0
  end
end