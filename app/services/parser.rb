class Parser
  FIELDS = %i[title description image_url prep_time cook_time total_time servings source_domain external_rating external_rating_count].freeze

  # A fixed allowlist of accented-letter named entities — deliberately NOT a
  # blanket CGI.unescapeHTML. Decoding HTML-syntax entities (&lt; &gt; &amp;
  # &quot; or numeric refs like &#60;) would reconstruct real tag-syntax
  # characters in stored text; views already escape on render, but there's no
  # reason for parsed recipe text to ever contain live-looking markup at all.
  SAFE_HTML_ENTITIES = {
    "&aring;" => "å", "&Aring;" => "Å",
    "&auml;" => "ä", "&Auml;" => "Ä",
    "&ouml;" => "ö", "&Ouml;" => "Ö",
    "&eacute;" => "é", "&Eacute;" => "É",
    "&egrave;" => "è", "&Egrave;" => "È",
    "&uuml;" => "ü", "&Uuml;" => "Ü",
    "&ntilde;" => "ñ", "&Ntilde;" => "Ñ",
    "&ccedil;" => "ç", "&Ccedil;" => "Ç",
    "&oslash;" => "ø", "&Oslash;" => "Ø",
    "&aelig;" => "æ", "&AElig;" => "Æ",
    "&nbsp;" => " "
  }.freeze

  def call
    raise NotImplementedError
  end

  private

  def normalize(result)
    result.symbolize_keys.slice(*FIELDS).transform_values { |value| clean(value) }
  end

  def clean(value)
    return value unless value.is_a?(String)
    decode_entities(value).presence
  end

  def decode_entities(value)
    return value unless value.is_a?(String)
    SAFE_HTML_ENTITIES.reduce(value) { |str, (entity, char)| str.gsub(entity, char) }
  end
end
