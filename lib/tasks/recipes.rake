namespace :recipes do
  desc "Decode any raw HTML entities (e.g. &auml;) still stored in recipe title/description, ingredient content/name, or step content — recipes scraped before Parser#decode_entities covered this field. Pure DB fix, no re-fetching or LLM calls. Set DRY_RUN=true to only list affected rows."
  task decode_entities: :environment do
    entity_pattern = /&[a-zA-Z]+;/

    decode = ->(value) { Parser::SAFE_HTML_ENTITIES.reduce(value) { |str, (entity, char)| str.gsub(entity, char) } }

    fixed = 0

    { Recipe => %i[title description], Ingredient => %i[content name], Step => %i[content] }.each do |klass, columns|
      columns.each do |column|
        klass.where("#{column} LIKE ?", "%&%;%").find_each do |record|
          value = record[column]
          next unless value.is_a?(String) && value.match?(entity_pattern)

          decoded = decode.call(value)
          next if decoded == value

          puts "#{klass.name} ##{record.id} #{column}: #{value.truncate(60)} -> #{decoded.truncate(60)}"

          unless ENV["DRY_RUN"].present?
            record.update!(column => decoded)
            fixed += 1
          end
        rescue => e
          puts "#{klass.name} ##{record.id} #{column}: FAILED (#{e.class}: #{e.message})"
        end
      end
    end

    puts(ENV["DRY_RUN"].present? ? "DRY_RUN set, nothing changed." : "Fixed #{fixed} value(s).")
  end
end
